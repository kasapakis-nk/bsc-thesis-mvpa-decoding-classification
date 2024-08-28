# Define the directory containing the LaTeX files
$directory = "C:\Users\User\Desktop\MikTeX path"

# Define the LaTeX source file and output PDF file
$texFile = Join-Path $directory "main.tex"
$pdfFile = Join-Path $directory "main.pdf"

# Change to the directory containing the LaTeX files
Set-Location $directory

# Check if the LaTeX source file exists
if (-Not (Test-Path $texFile)) {
    Write-Host "The file $texFile does not exist."
    exit 1
}

# Run xelatex to compile the LaTeX file
Write-Host "Compiling $texFile with xelatex..."
& xelatex $texFile

# Check if the PDF was generated successfully
if (-Not (Test-Path $pdfFile)) {
    Write-Host "The PDF file $pdfFile was not created. There may have been an error in compilation."
    exit 1
}

# Open the resulting PDF file
Write-Host "Opening $pdfFile..."
Start-Process $pdfFile