// Lemon Math Web App - JavaScript

// State
let currentImage = null;
let currentImageBase64 = null;

// DOM Elements
const apiKeySection = document.getElementById('apiKeySection');
const mainApp = document.getElementById('mainApp');
const settingsBtn = document.getElementById('settingsBtn');
const loadingSection = document.getElementById('loadingSection');
const resultsSection = document.getElementById('resultsSection');
const errorSection = document.getElementById('errorSection');
const solveBtn = document.getElementById('solveBtn');
const imagePreview = document.getElementById('imagePreview');
const previewImg = document.getElementById('previewImg');

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    checkApiKey();
});

// Check if API key exists
function checkApiKey() {
    const apiKey = localStorage.getItem('geminiApiKey');
    if (apiKey) {
        showMainApp();
    } else {
        showApiKeySection();
    }
}

// Show/Hide Sections
function showApiKeySection() {
    apiKeySection.style.display = 'flex';
    mainApp.style.display = 'none';
    settingsBtn.style.display = 'none';
}

function showMainApp() {
    apiKeySection.style.display = 'none';
    mainApp.style.display = 'block';
    settingsBtn.style.display = 'block';
    resetToUpload();
}

function resetToUpload() {
    loadingSection.style.display = 'none';
    resultsSection.style.display = 'none';
    errorSection.style.display = 'none';
    document.querySelector('.upload-section').style.display = 'block';
}

// API Key Functions
function toggleApiKeyVisibility() {
    const input = document.getElementById('apiKeyInput');
    const btn = document.getElementById('toggleKeyBtn');
    if (input.type === 'password') {
        input.type = 'text';
        btn.textContent = '🙈';
    } else {
        input.type = 'password';
        btn.textContent = '👁️';
    }
}

function saveApiKey() {
    const apiKey = document.getElementById('apiKeyInput').value.trim();
    if (!apiKey) {
        alert('Please enter your API key');
        return;
    }
    localStorage.setItem('geminiApiKey', apiKey);
    showMainApp();
}

function updateApiKey() {
    const apiKey = document.getElementById('settingsApiKey').value.trim();
    if (apiKey) {
        localStorage.setItem('geminiApiKey', apiKey);
        alert('API key updated!');
        closeSettings();
    }
}

function clearApiKey() {
    if (confirm('Are you sure you want to clear your API key and all data?')) {
        localStorage.clear();
        showApiKeySection();
        closeSettings();
    }
}

// Image Handling
function handleImageUpload(event) {
    const file = event.target.files[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
        alert('Please select an image file');
        return;
    }

    currentImage = file;

    // Convert to base64
    const reader = new FileReader();
    reader.onload = (e) => {
        currentImageBase64 = e.target.result.split(',')[1];
        previewImg.src = e.target.result;
        imagePreview.style.display = 'block';
        solveBtn.disabled = false;
    };
    reader.readAsDataURL(file);
}

function clearImage() {
    currentImage = null;
    currentImageBase64 = null;
    imagePreview.style.display = 'none';
    previewImg.src = '';
    solveBtn.disabled = true;

    // Reset file inputs
    document.querySelectorAll('input[type="file"]').forEach(input => {
        input.value = '';
    });
}

// Solve Problem
async function solveProblem() {
    if (!currentImageBase64) {
        alert('Please upload an image first');
        return;
    }

    const apiKey = localStorage.getItem('geminiApiKey');
    if (!apiKey) {
        alert('API key not found. Please add your API key in settings.');
        return;
    }

    // Show loading
    document.querySelector('.upload-section').style.display = 'none';
    loadingSection.style.display = 'block';
    resultsSection.style.display = 'none';
    errorSection.style.display = 'none';

    try {
        const result = await callGeminiAPI(apiKey, currentImageBase64);
        displayResults(result);
    } catch (error) {
        displayError(error.message);
    }
}

// Gemini API Call
async function callGeminiAPI(apiKey, imageBase64) {
    const language = localStorage.getItem('language') || 'english';
    const includeAlternatives = localStorage.getItem('includeAlternatives') !== 'false';
    const includeExamples = localStorage.getItem('includeExamples') !== 'false';

    const languageName = language === 'greek' ? 'Greek' : 'English';

    const prompt = `You are an expert math tutor with exceptional skill at reading handwritten mathematics.
Analyze this image and solve the math problem shown. Respond in ${languageName}.

HANDWRITING RECOGNITION GUIDELINES:
1. Handle natural handwriting variations:
   - Slanted/italic writing style
   - Inconsistent letter and symbol spacing
   - Variable stroke thickness (thin pencil to thick marker)
   - Connected or overlapping characters

2. Distinguish similar-looking symbols:
   - Numbers: 0 vs O, 1 vs l vs I, 2 vs Z, 5 vs S
   - Variables: x vs ×, n vs h, u vs v
   - Greek: θ vs 0, π vs n, Σ vs E

3. Recognize complex mathematical structures:
   - Fractions with horizontal bars
   - Exponents and subscripts
   - Square roots and nth roots
   - Integrals, summations, limits
   - Matrices and determinants

Return a JSON object with this exact structure:
{
    "recognizedText": "the math problem as text",
    "problemType": "algebra|geometry|calculus|arithmetic|trigonometry|statistics|unknown",
    "solution": "the final answer",
    "confidence": 0.95,
    "steps": [
        {
            "stepNumber": 1,
            "title": "Step title",
            "explanation": "What we're doing and why",
            "mathExpression": "The mathematical work",
            "hint": "A helpful tip (optional)"
        }
    ]${includeAlternatives ? `,
    "alternativeMethods": [
        {
            "name": "Method name",
            "description": "When to use this method",
            "difficulty": "beginner|intermediate|advanced"
        }
    ]` : ''}${includeExamples ? `,
    "realWorldExamples": [
        {
            "title": "Example title",
            "scenario": "Real-world situation",
            "application": "How this math applies"
        }
    ]` : ''}
}

IMPORTANT: Return ONLY valid JSON, no markdown code blocks.`;

    const requestBody = {
        contents: [{
            parts: [
                { text: prompt },
                {
                    inline_data: {
                        mime_type: "image/jpeg",
                        data: imageBase64
                    }
                }
            ]
        }],
        generationConfig: {
            temperature: 0.1,
            maxOutputTokens: 4096
        }
    };

    const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`,
        {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(requestBody)
        }
    );

    if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        if (response.status === 400) {
            throw new Error('Invalid request. Please try a different image.');
        } else if (response.status === 401 || response.status === 403) {
            throw new Error('Invalid API key. Please check your API key in settings.');
        } else if (response.status === 429) {
            throw new Error('Too many requests. Please wait a moment and try again.');
        } else {
            throw new Error(errorData.error?.message || 'Failed to analyze the image. Please try again.');
        }
    }

    const data = await response.json();

    if (!data.candidates || !data.candidates[0]?.content?.parts?.[0]?.text) {
        throw new Error('No response from AI. Please try a clearer image.');
    }

    const responseText = data.candidates[0].content.parts[0].text;

    // Clean up the response (remove markdown code blocks if present)
    let cleanedText = responseText
        .replace(/```json\n?/g, '')
        .replace(/```\n?/g, '')
        .trim();

    try {
        return JSON.parse(cleanedText);
    } catch (e) {
        console.error('Failed to parse response:', cleanedText);
        throw new Error('Failed to parse the solution. Please try again.');
    }
}

// Display Results
function displayResults(result) {
    loadingSection.style.display = 'none';
    resultsSection.style.display = 'block';

    // Recognized Text
    document.getElementById('recognizedText').textContent = result.recognizedText || 'Could not recognize';

    // Problem Type
    document.getElementById('problemType').textContent = result.problemType || 'Unknown';

    // Confidence Badge
    const confidenceBadge = document.getElementById('confidenceBadge');
    const confidence = result.confidence || 0;
    confidenceBadge.textContent = `${Math.round(confidence * 100)}% confident`;
    if (confidence >= 0.8) {
        confidenceBadge.className = 'confidence-badge';
    } else if (confidence >= 0.5) {
        confidenceBadge.className = 'confidence-badge medium';
    } else {
        confidenceBadge.className = 'confidence-badge low';
    }

    // Solution
    document.getElementById('solutionText').textContent = result.solution || 'No solution found';

    // Steps
    const stepsContainer = document.getElementById('stepsContainer');
    stepsContainer.innerHTML = '';

    if (result.steps && result.steps.length > 0) {
        result.steps.forEach((step, index) => {
            const stepEl = document.createElement('div');
            stepEl.className = 'step-item';
            stepEl.innerHTML = `
                <div class="step-header">
                    <span class="step-number">${step.stepNumber || index + 1}</span>
                    <span class="step-title">${escapeHtml(step.title || `Step ${index + 1}`)}</span>
                </div>
                <p class="step-explanation">${escapeHtml(step.explanation || '')}</p>
                <div class="step-math">${escapeHtml(step.mathExpression || '')}</div>
                ${step.hint ? `<div class="step-hint">${escapeHtml(step.hint)}</div>` : ''}
            `;
            stepsContainer.appendChild(stepEl);
        });
    } else {
        stepsContainer.innerHTML = '<p>No steps available</p>';
    }

    // Alternative Methods
    const altCard = document.getElementById('alternativeMethodsCard');
    const altContainer = document.getElementById('alternativesContainer');
    if (result.alternativeMethods && result.alternativeMethods.length > 0) {
        altCard.style.display = 'block';
        altContainer.innerHTML = '';
        result.alternativeMethods.forEach(method => {
            const methodEl = document.createElement('div');
            methodEl.className = 'alternative-item';
            methodEl.innerHTML = `
                <div class="alternative-header">
                    <span class="alternative-name">${escapeHtml(method.name)}</span>
                    <span class="difficulty-badge ${method.difficulty}">${method.difficulty}</span>
                </div>
                <p>${escapeHtml(method.description)}</p>
            `;
            altContainer.appendChild(methodEl);
        });
    } else {
        altCard.style.display = 'none';
    }

    // Real World Examples
    const exCard = document.getElementById('realWorldCard');
    const exContainer = document.getElementById('examplesContainer');
    if (result.realWorldExamples && result.realWorldExamples.length > 0) {
        exCard.style.display = 'block';
        exContainer.innerHTML = '';
        result.realWorldExamples.forEach(example => {
            const exEl = document.createElement('div');
            exEl.className = 'example-item';
            exEl.innerHTML = `
                <div class="example-title">${escapeHtml(example.title)}</div>
                <p class="example-scenario">${escapeHtml(example.scenario)}</p>
                <p class="example-application">${escapeHtml(example.application)}</p>
            `;
            exContainer.appendChild(exEl);
        });
    } else {
        exCard.style.display = 'none';
    }

    // Scroll to results
    resultsSection.scrollIntoView({ behavior: 'smooth' });
}

// Display Error
function displayError(message) {
    loadingSection.style.display = 'none';
    errorSection.style.display = 'block';
    document.getElementById('errorMessage').textContent = message;
}

// New Problem
function newProblem() {
    clearImage();
    resetToUpload();
    document.querySelector('.upload-section').style.display = 'block';
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Copy Results
function copyResults() {
    const recognizedText = document.getElementById('recognizedText').textContent;
    const solution = document.getElementById('solutionText').textContent;
    const steps = Array.from(document.querySelectorAll('.step-item')).map(step => {
        const title = step.querySelector('.step-title')?.textContent || '';
        const explanation = step.querySelector('.step-explanation')?.textContent || '';
        const math = step.querySelector('.step-math')?.textContent || '';
        return `${title}\n${explanation}\n${math}`;
    }).join('\n\n');

    const text = `Problem: ${recognizedText}\n\nSolution: ${solution}\n\nSteps:\n${steps}`;

    navigator.clipboard.writeText(text).then(() => {
        alert('Results copied to clipboard!');
    }).catch(() => {
        alert('Failed to copy. Please try selecting the text manually.');
    });
}

// Settings
function showSettings() {
    document.getElementById('settingsModal').style.display = 'flex';
    document.getElementById('settingsApiKey').value = localStorage.getItem('geminiApiKey') || '';
    document.getElementById('languageSelect').value = localStorage.getItem('language') || 'english';
    document.getElementById('includeAlternatives').checked = localStorage.getItem('includeAlternatives') !== 'false';
    document.getElementById('includeExamples').checked = localStorage.getItem('includeExamples') !== 'false';
}

function closeSettings() {
    document.getElementById('settingsModal').style.display = 'none';

    // Save settings
    localStorage.setItem('language', document.getElementById('languageSelect').value);
    localStorage.setItem('includeAlternatives', document.getElementById('includeAlternatives').checked);
    localStorage.setItem('includeExamples', document.getElementById('includeExamples').checked);
}

// Utility: Escape HTML
function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Close modal when clicking outside
document.getElementById('settingsModal')?.addEventListener('click', (e) => {
    if (e.target.id === 'settingsModal') {
        closeSettings();
    }
});
