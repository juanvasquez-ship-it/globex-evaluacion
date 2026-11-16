$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath($PSScriptRoot)
$notebookPath = Join-Path $projectRoot '02_Ejecutar_Bancos.ipynb'
$requirementsPath = Join-Path $projectRoot 'requirements_notebook.txt'

function Test-TaskPython([string]$commandPath, [string[]]$prefixArgs = @()) {
    try {
        $result = & $commandPath @prefixArgs -c "import sys; print(sys.executable if (3,10) <= sys.version_info < (3,14) else '')" 2>$null
        if ($LASTEXITCODE -eq 0 -and $result -and (Test-Path -LiteralPath $result)) { return [string]$result }
    } catch { }
    return $null
}

function Find-TaskPython {
    $launcher = Get-Command py -ErrorAction SilentlyContinue
    if ($launcher) {
        foreach ($version in @('-3.12', '-3.13', '-3.11', '-3.10')) {
            $candidate = Test-TaskPython $launcher.Source @($version)
            if ($candidate) { return $candidate }
        }
    }
    foreach ($version in @('312', '313', '311', '310')) {
        $candidate = Join-Path $env:LOCALAPPDATA ('Programs\Python\Python' + $version + '\python.exe')
        if (Test-Path -LiteralPath $candidate) {
            $valid = Test-TaskPython $candidate
            if ($valid) { return $valid }
        }
    }
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCommand -and $pythonCommand.Source -notmatch 'WindowsApps') {
        return Test-TaskPython $pythonCommand.Source
    }
    return $null
}

function Find-TaskCode {
    $command = Get-Command code -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    foreach ($candidate in @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'),
        (Join-Path $env:ProgramFiles 'Microsoft VS Code\bin\code.cmd')
    )) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    return $null
}

try {
    if (-not (Test-Path -LiteralPath $notebookPath) -or -not (Test-Path -LiteralPath $requirementsPath)) {
        throw 'Faltan archivos de entrega. Descargue y descomprima el repositorio completo.'
    }
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    $taskPython = Find-TaskPython
    if (-not $taskPython) {
        if (-not $winget) { throw 'No se encontro Python 3.10-3.13 ni winget. Use Google Colab o instale Python 3.12.' }
        Write-Host 'Instalando Python 3.12 para el usuario actual...'
        & $winget.Source install --id Python.Python.3.12 --exact --scope user --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo instalar Python. Compruebe internet y los permisos del equipo.' }
        $taskPython = Find-TaskPython
        if (-not $taskPython) { throw 'Python no se encontro despues de instalarlo. Vuelva a abrir el preparador.' }
    }
    $environmentDirectory = Join-Path $projectRoot '.venv'
    $environmentPython = Join-Path $environmentDirectory 'Scripts\python.exe'
    if (-not (Test-Path -LiteralPath $environmentPython)) {
        Write-Host 'Creando el entorno de Globex...'
        & $taskPython -m venv $environmentDirectory
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el entorno de Python.' }
    }
    $validEnvironment = Test-TaskPython $environmentPython
    if (-not $validEnvironment) { throw 'El entorno local no funciona. Vuelva a descomprimir el repositorio en una carpeta estable y ejecute el preparador.' }
    $certificateBundle = Join-Path $environmentDirectory 'certificados_sistema.pem'
    & $environmentPython -c "import ssl,sys,pathlib; certs=ssl.create_default_context().get_ca_certs(binary_form=True); pathlib.Path(sys.argv[1]).write_text(''.join(ssl.DER_cert_to_PEM_cert(c) for c in certs),encoding='ascii'); sys.exit(0 if certs else 1)" $certificateBundle
    if ($LASTEXITCODE -ne 0) { throw 'No se pudieron leer los certificados de confianza del sistema.' }
    Write-Host 'Preparando las dependencias del kernel...'
    & $environmentPython -m pip install --cert $certificateBundle --disable-pip-version-check --no-input -r $requirementsPath
    if ($LASTEXITCODE -ne 0) { throw 'No se pudieron instalar las dependencias. Compruebe internet, proxy o certificados del equipo.' }
    & $environmentPython -m pip check
    if ($LASTEXITCODE -ne 0) { throw 'Las dependencias instaladas no son compatibles entre si.' }
    & $environmentPython -c 'import sys,ipykernel; assert sys.version_info >= (3,10)'
    if ($LASTEXITCODE -ne 0) { throw 'El interprete o el kernel de Globex no esta operativo.' }
    $rootBytes = [System.Text.Encoding]::UTF8.GetBytes($projectRoot.ToLowerInvariant())
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    try { $folderHash = [System.BitConverter]::ToString($hasher.ComputeHash($rootBytes)).Replace('-', '').Substring(0, 10).ToLowerInvariant() }
    finally { $hasher.Dispose() }
    $kernelName = 'globex-final-' + $folderHash
    & $environmentPython -m ipykernel install --user --name $kernelName --display-name 'Python (Globex)'
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo registrar el kernel de Globex.' }
    $settingsDirectory = Join-Path $projectRoot '.vscode'
    New-Item -ItemType Directory -Path $settingsDirectory -Force | Out-Null
    [ordered]@{
        'python.defaultInterpreterPath' = $environmentPython
        'python.terminal.executeInFileDir' = $true
    } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $settingsDirectory 'settings.json') -Encoding UTF8
    $configureKernel = @'
import json,sys
from pathlib import Path
path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding='utf-8'))
data['metadata']['kernelspec'] = {'display_name':'Python (Globex)','language':'python','name':sys.argv[2]}
path.write_text(json.dumps(data,ensure_ascii=False,indent=1)+'\n',encoding='utf-8')
'@
    & $environmentPython -c $configureKernel $notebookPath $kernelName
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo configurar el kernel del notebook.' }
    $taskCode = Find-TaskCode
    if (-not $taskCode) {
        if (-not $winget) { throw 'El entorno esta preparado, pero no hay VS Code ni winget. Instale VS Code o utilice Colab.' }
        Write-Host 'Instalando VS Code para el usuario actual...'
        & $winget.Source install --id Microsoft.VisualStudioCode --exact --scope user --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo instalar VS Code. Compruebe los permisos del equipo.' }
        $taskCode = Find-TaskCode
        if (-not $taskCode) { throw 'VS Code no se encontro despues de instalarlo. Vuelva a abrir el preparador.' }
    }
    $extensions = & $taskCode --list-extensions
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar la configuracion de VS Code.' }
    foreach ($extension in @('ms-python.python', 'ms-toolsai.jupyter')) {
        if ($extensions -notcontains $extension) {
            & $taskCode --install-extension $extension
            if ($LASTEXITCODE -ne 0) { throw ('No se pudo instalar la extension ' + $extension) }
        }
    }
    Write-Host 'Listo. En el notebook pulse Ejecutar todo e introduzca la clave cuando se solicite.'
    & $taskCode --new-window $projectRoot $notebookPath
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo abrir VS Code. Abra 02_Ejecutar_Bancos.ipynb desde el editor.' }
} catch {
    Write-Host ('No se completo la preparacion: ' + $_.Exception.Message)
    exit 1
}
