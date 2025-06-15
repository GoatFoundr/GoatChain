# Kill any existing Geth processes
Get-Process -Name "geth" -ErrorAction SilentlyContinue | Stop-Process -Force

# Create password file if it doesn't exist
$passwordFile = "~/goat-chain/password.txt"
if (-not (Test-Path $passwordFile)) {
    "your-password-here" | Out-File -FilePath $passwordFile -Encoding utf8
}

# Initialize Geth if not already initialized
if (-not (Test-Path "~/goat-chain/data/geth")) {
    Write-Host "Initializing Geth..."
    geth --datadir "~/goat-chain/data" init "~/goat-chain/genesis.json"
}

# Start Geth with proper configuration
Write-Host "Starting Geth..."
geth --config "~/goat-chain/geth-config.toml" --datadir "~/goat-chain/data" --password "~/goat-chain/password.txt" --allow-insecure-unlock --unlock "0x7c0d52faab596c08f484e3478aebc6205f3f5d8c" --mine --miner.threads=1 --verbosity 3 