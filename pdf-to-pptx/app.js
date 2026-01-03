/**
 * PDF to PPTX Converter
 * Converts PDF documents to PowerPoint presentations using PDF.js and PptxGenJS
 */

// Set up PDF.js worker
pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';

// DOM Elements
const dropZone = document.getElementById('drop-zone');
const fileInput = document.getElementById('file-input');
const uploadSection = document.getElementById('upload-section');
const fileInfo = document.getElementById('file-info');
const fileName = document.getElementById('file-name');
const fileSize = document.getElementById('file-size');
const pageCount = document.getElementById('page-count');
const removeFileBtn = document.getElementById('remove-file');
const optionsSection = document.getElementById('options-section');
const convertBtn = document.getElementById('convert-btn');
const slideSizeSelect = document.getElementById('slide-size');
const imageQualitySelect = document.getElementById('image-quality');
const progressSection = document.getElementById('progress-section');
const progressText = document.getElementById('progress-text');
const progressPercent = document.getElementById('progress-percent');
const progressFill = document.getElementById('progress-fill');
const progressDetail = document.getElementById('progress-detail');
const successSection = document.getElementById('success-section');
const downloadBtn = document.getElementById('download-btn');
const convertAnother = document.getElementById('convert-another');
const errorSection = document.getElementById('error-section');
const errorMessage = document.getElementById('error-message');
const tryAgainBtn = document.getElementById('try-again');

// State
let selectedFile = null;
let pdfDocument = null;
let generatedBlob = null;

// Slide layout dimensions (in inches)
const SLIDE_LAYOUTS = {
    'LAYOUT_16x9': { width: 10, height: 5.625 },
    'LAYOUT_4x3': { width: 10, height: 7.5 },
    'LAYOUT_16x10': { width: 10, height: 6.25 },
    'LAYOUT_WIDE': { width: 13.333, height: 7.5 }
};

// Event Listeners
dropZone.addEventListener('click', () => fileInput.click());
fileInput.addEventListener('change', handleFileSelect);
dropZone.addEventListener('dragover', handleDragOver);
dropZone.addEventListener('dragleave', handleDragLeave);
dropZone.addEventListener('drop', handleDrop);
removeFileBtn.addEventListener('click', resetUpload);
convertBtn.addEventListener('click', startConversion);
downloadBtn.addEventListener('click', downloadPptx);
convertAnother.addEventListener('click', resetAll);
tryAgainBtn.addEventListener('click', resetAll);

/**
 * Handle file selection from input
 */
function handleFileSelect(e) {
    const file = e.target.files[0];
    if (file) {
        processFile(file);
    }
}

/**
 * Handle drag over event
 */
function handleDragOver(e) {
    e.preventDefault();
    e.stopPropagation();
    dropZone.classList.add('drag-over');
}

/**
 * Handle drag leave event
 */
function handleDragLeave(e) {
    e.preventDefault();
    e.stopPropagation();
    dropZone.classList.remove('drag-over');
}

/**
 * Handle file drop
 */
function handleDrop(e) {
    e.preventDefault();
    e.stopPropagation();
    dropZone.classList.remove('drag-over');

    const file = e.dataTransfer.files[0];
    if (file && file.type === 'application/pdf') {
        processFile(file);
    } else {
        showError('Please select a valid PDF file.');
    }
}

/**
 * Process the selected PDF file
 */
async function processFile(file) {
    if (file.type !== 'application/pdf') {
        showError('Please select a valid PDF file.');
        return;
    }

    selectedFile = file;

    // Display file info
    fileName.textContent = file.name;
    fileSize.textContent = formatFileSize(file.size);

    // Load PDF to get page count
    try {
        const arrayBuffer = await file.arrayBuffer();
        pdfDocument = await pdfjsLib.getDocument({ data: arrayBuffer }).promise;
        pageCount.textContent = `${pdfDocument.numPages} page${pdfDocument.numPages !== 1 ? 's' : ''} detected`;

        // Show file info and options
        uploadSection.classList.add('hidden');
        fileInfo.classList.remove('hidden');
        optionsSection.classList.remove('hidden');
    } catch (error) {
        console.error('Error loading PDF:', error);
        showError('Failed to load PDF. The file may be corrupted or password protected.');
    }
}

/**
 * Format file size for display
 */
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

/**
 * Start the conversion process
 */
async function startConversion() {
    if (!pdfDocument) {
        showError('No PDF loaded.');
        return;
    }

    // Hide options, show progress
    optionsSection.classList.add('hidden');
    fileInfo.classList.add('hidden');
    progressSection.classList.remove('hidden');
    progressSection.classList.add('converting');

    try {
        await convertPdfToPptx();
        showSuccess();
    } catch (error) {
        console.error('Conversion error:', error);
        showError(`Conversion failed: ${error.message}`);
    }
}

/**
 * Convert PDF to PPTX
 */
async function convertPdfToPptx() {
    const slideLayout = slideSizeSelect.value;
    const scale = parseFloat(imageQualitySelect.value);
    const numPages = pdfDocument.numPages;
    const layoutDimensions = SLIDE_LAYOUTS[slideLayout];

    // Create new presentation
    const pptx = new PptxGenJS();
    pptx.layout = slideLayout;
    pptx.author = 'PDF to PPTX Converter';
    pptx.title = selectedFile.name.replace('.pdf', '');
    pptx.subject = 'Converted from PDF';

    updateProgress(0, 'Initializing conversion...');

    for (let i = 1; i <= numPages; i++) {
        updateProgress(
            Math.round((i - 1) / numPages * 90),
            `Processing page ${i} of ${numPages}...`
        );

        // Get the page
        const page = await pdfDocument.getPage(i);

        // Get page dimensions
        const viewport = page.getViewport({ scale: 1 });
        const pageWidth = viewport.width;
        const pageHeight = viewport.height;

        // Calculate the scale to fit the slide while maintaining aspect ratio
        const slideWidthPx = layoutDimensions.width * 96; // 96 DPI
        const slideHeightPx = layoutDimensions.height * 96;

        const scaleX = slideWidthPx / pageWidth;
        const scaleY = slideHeightPx / pageHeight;
        const fitScale = Math.min(scaleX, scaleY) * scale;

        // Create canvas for rendering
        const scaledViewport = page.getViewport({ scale: fitScale });
        const canvas = document.createElement('canvas');
        const context = canvas.getContext('2d');
        canvas.width = scaledViewport.width;
        canvas.height = scaledViewport.height;

        // Render PDF page to canvas
        await page.render({
            canvasContext: context,
            viewport: scaledViewport
        }).promise;

        // Convert canvas to base64 image
        const imageData = canvas.toDataURL('image/png');

        // Add slide
        const slide = pptx.addSlide();

        // Calculate positioning to center the image
        const imgWidthInches = scaledViewport.width / 96;
        const imgHeightInches = scaledViewport.height / 96;
        const xPos = (layoutDimensions.width - imgWidthInches) / 2;
        const yPos = (layoutDimensions.height - imgHeightInches) / 2;

        // Add image to slide
        slide.addImage({
            data: imageData,
            x: xPos,
            y: yPos,
            w: imgWidthInches,
            h: imgHeightInches
        });

        // Clean up
        canvas.remove();
    }

    updateProgress(95, 'Generating PowerPoint file...');

    // Generate the PPTX file
    generatedBlob = await pptx.write({ outputType: 'blob' });

    updateProgress(100, 'Conversion complete!');
}

/**
 * Update progress display
 */
function updateProgress(percent, detail) {
    progressFill.style.width = `${percent}%`;
    progressPercent.textContent = `${percent}%`;
    progressDetail.textContent = detail;
}

/**
 * Show success state
 */
function showSuccess() {
    progressSection.classList.add('hidden');
    progressSection.classList.remove('converting');
    successSection.classList.remove('hidden');
}

/**
 * Show error state
 */
function showError(message) {
    progressSection.classList.add('hidden');
    progressSection.classList.remove('converting');
    optionsSection.classList.add('hidden');
    fileInfo.classList.add('hidden');
    errorMessage.textContent = message;
    errorSection.classList.remove('hidden');
}

/**
 * Download the generated PPTX file
 */
function downloadPptx() {
    if (!generatedBlob) return;

    const url = URL.createObjectURL(generatedBlob);
    const a = document.createElement('a');
    a.href = url;
    a.download = selectedFile.name.replace('.pdf', '.pptx');
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

/**
 * Reset upload state
 */
function resetUpload() {
    selectedFile = null;
    pdfDocument = null;
    fileInput.value = '';

    fileInfo.classList.add('hidden');
    optionsSection.classList.add('hidden');
    uploadSection.classList.remove('hidden');
}

/**
 * Reset all state
 */
function resetAll() {
    selectedFile = null;
    pdfDocument = null;
    generatedBlob = null;
    fileInput.value = '';

    // Reset progress
    progressFill.style.width = '0%';
    progressPercent.textContent = '0%';
    progressDetail.textContent = 'Initializing...';

    // Hide all sections except upload
    fileInfo.classList.add('hidden');
    optionsSection.classList.add('hidden');
    progressSection.classList.add('hidden');
    progressSection.classList.remove('converting');
    successSection.classList.add('hidden');
    errorSection.classList.add('hidden');
    uploadSection.classList.remove('hidden');
}
