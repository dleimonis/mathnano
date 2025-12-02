// Lemon Math Web App - Full Featured Version

// ==================== STATE ====================
let currentImage = null;
let currentImageBase64 = null;
let currentSlide = 0;
let currentTool = 'pen';
let brushSize = 4;
let isDrawing = false;
let lastX = 0;
let lastY = 0;
let canvas = null;
let ctx = null;
let adminPressTimer = null;
let lastResult = null;
let currentFilter = 'all';
let currentSort = 'newest';
let mathChart = null;

// ==================== ACHIEVEMENTS DEFINITION ====================
const ACHIEVEMENTS = [
    { id: 'first_problem', name: 'First Steps', icon: '🎯', description: 'Solve your first problem', condition: (stats) => stats.totalSolved >= 1 },
    { id: 'five_problems', name: 'Getting Started', icon: '📚', description: 'Solve 5 problems', condition: (stats) => stats.totalSolved >= 5 },
    { id: 'ten_problems', name: 'Math Explorer', icon: '🔍', description: 'Solve 10 problems', condition: (stats) => stats.totalSolved >= 10 },
    { id: 'fifty_problems', name: 'Problem Crusher', icon: '💪', description: 'Solve 50 problems', condition: (stats) => stats.totalSolved >= 50 },
    { id: 'hundred_problems', name: 'Math Master', icon: '🏆', description: 'Solve 100 problems', condition: (stats) => stats.totalSolved >= 100 },
    { id: 'streak_3', name: 'On Fire', icon: '🔥', description: '3 day streak', condition: (stats) => stats.streak >= 3 },
    { id: 'streak_7', name: 'Week Warrior', icon: '⚡', description: '7 day streak', condition: (stats) => stats.streak >= 7 },
    { id: 'streak_30', name: 'Monthly Champion', icon: '👑', description: '30 day streak', condition: (stats) => stats.streak >= 30 },
    { id: 'algebra_5', name: 'Algebra Ace', icon: '➕', description: 'Solve 5 algebra problems', condition: (stats) => (stats.byType?.algebra || 0) >= 5 },
    { id: 'calculus_5', name: 'Calculus Conqueror', icon: '∫', description: 'Solve 5 calculus problems', condition: (stats) => (stats.byType?.calculus || 0) >= 5 },
    { id: 'geometry_5', name: 'Geometry Guru', icon: '📐', description: 'Solve 5 geometry problems', condition: (stats) => (stats.byType?.geometry || 0) >= 5 },
    { id: 'night_owl', name: 'Night Owl', icon: '🦉', description: 'Solve a problem after midnight', condition: (stats) => stats.nightOwl },
    { id: 'early_bird', name: 'Early Bird', icon: '🐦', description: 'Solve a problem before 6 AM', condition: (stats) => stats.earlyBird },
    { id: 'draw_master', name: 'Artist', icon: '🎨', description: 'Solve 5 problems by drawing', condition: (stats) => (stats.drawSolved || 0) >= 5 },
];

// ==================== INITIALIZATION ====================
document.addEventListener('DOMContentLoaded', () => {
    initializeApp();
});

function initializeApp() {
    loadTheme();
    loadSettings();
    checkFirstVisit();
    checkApiKey();
    initializeCanvas();
    updateStats();
    updateUsageDisplay();
    setupAdminAccess();
    loadHistory();
}

// ==================== THEME ====================
function loadTheme() {
    const savedTheme = localStorage.getItem('theme') || 'auto';
    applyTheme(savedTheme);
    updateThemeButtons(savedTheme);
}

function applyTheme(theme) {
    if (theme === 'auto') {
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        document.body.setAttribute('data-theme', prefersDark ? 'dark' : 'light');
    } else {
        document.body.setAttribute('data-theme', theme);
    }
}

function setTheme(theme) {
    localStorage.setItem('theme', theme);
    applyTheme(theme);
    updateThemeButtons(theme);
    triggerHaptic();
}

function updateThemeButtons(theme) {
    document.querySelectorAll('.theme-option').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.theme === theme);
    });
}

function toggleTheme() {
    const current = document.body.getAttribute('data-theme');
    const newTheme = current === 'dark' ? 'light' : 'dark';
    setTheme(newTheme);
}

// ==================== ONBOARDING ====================
function checkFirstVisit() {
    const hasVisited = localStorage.getItem('hasVisited');
    if (!hasVisited) {
        showOnboarding();
    }
}

function showOnboarding() {
    document.getElementById('onboardingOverlay').style.display = 'flex';
    currentSlide = 0;
    updateSlides();
}

function showTutorial() {
    closeSettings();
    showOnboarding();
}

function updateSlides() {
    document.querySelectorAll('.onboarding-slide').forEach((slide, i) => {
        slide.classList.toggle('active', i === currentSlide);
    });
    document.querySelectorAll('.onboarding-dots .dot').forEach((dot, i) => {
        dot.classList.toggle('active', i === currentSlide);
    });

    const nextBtn = document.querySelector('.next-btn');
    if (currentSlide === 3) {
        nextBtn.textContent = 'Get Started';
    } else {
        nextBtn.textContent = 'Next';
    }
}

function nextSlide() {
    if (currentSlide < 3) {
        currentSlide++;
        updateSlides();
        triggerHaptic();
    } else {
        skipOnboarding();
    }
}

function skipOnboarding() {
    document.getElementById('onboardingOverlay').style.display = 'none';
    localStorage.setItem('hasVisited', 'true');
    triggerHaptic();
}

// ==================== API KEY ====================
function checkApiKey() {
    const apiKey = localStorage.getItem('geminiApiKey');
    if (apiKey) {
        showMainApp();
    } else {
        showApiKeySection();
    }
}

function showApiKeySection() {
    document.getElementById('apiKeySection').style.display = 'flex';
    document.getElementById('mainApp').style.display = 'none';
    document.getElementById('usageBar').style.display = 'none';
}

function showMainApp() {
    document.getElementById('apiKeySection').style.display = 'none';
    document.getElementById('mainApp').style.display = 'block';
    document.getElementById('usageBar').style.display = 'block';
    resetToUpload();
}

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
        showToast('Please enter your API key', 'error');
        return;
    }
    localStorage.setItem('geminiApiKey', apiKey);
    showMainApp();
    showToast('API key saved successfully!', 'success');
    triggerHaptic();
}

function updateApiKey() {
    const apiKey = document.getElementById('settingsApiKey').value.trim();
    if (apiKey) {
        localStorage.setItem('geminiApiKey', apiKey);
        showToast('API key updated!', 'success');
        triggerHaptic();
    }
}

// ==================== TABS ====================
function switchTab(tab) {
    document.querySelectorAll('.nav-tab').forEach(t => {
        t.classList.toggle('active', t.dataset.tab === tab);
    });
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    document.getElementById(tab + 'Tab').classList.add('active');

    if (tab === 'history') {
        loadHistory();
    }
    triggerHaptic('light');
}

function showHistory() {
    switchTab('history');
}

// ==================== IMAGE HANDLING ====================
function handleImageUpload(event) {
    const file = event.target.files[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
        showToast('Please select an image file', 'error');
        return;
    }

    currentImage = file;
    const reader = new FileReader();
    reader.onload = (e) => {
        currentImageBase64 = e.target.result.split(',')[1];
        document.getElementById('previewImg').src = e.target.result;
        document.getElementById('imagePreview').style.display = 'block';
        document.getElementById('solveBtn').disabled = false;
    };
    reader.readAsDataURL(file);
    triggerHaptic();
}

function clearImage() {
    currentImage = null;
    currentImageBase64 = null;
    document.getElementById('imagePreview').style.display = 'none';
    document.getElementById('previewImg').src = '';
    document.getElementById('solveBtn').disabled = true;
    document.querySelectorAll('input[type="file"]').forEach(input => input.value = '');
}

// ==================== CANVAS DRAWING ====================
function initializeCanvas() {
    canvas = document.getElementById('drawCanvas');
    if (!canvas) return;

    ctx = canvas.getContext('2d');

    // Set actual canvas size
    const rect = canvas.getBoundingClientRect();
    canvas.width = rect.width;
    canvas.height = 300;

    // Set up drawing style
    ctx.strokeStyle = '#000';
    ctx.lineWidth = brushSize;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.fillStyle = '#fff';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Mouse events
    canvas.addEventListener('mousedown', startDrawing);
    canvas.addEventListener('mousemove', draw);
    canvas.addEventListener('mouseup', stopDrawing);
    canvas.addEventListener('mouseout', stopDrawing);

    // Touch events
    canvas.addEventListener('touchstart', handleTouchStart);
    canvas.addEventListener('touchmove', handleTouchMove);
    canvas.addEventListener('touchend', stopDrawing);
}

function startDrawing(e) {
    isDrawing = true;
    const pos = getPosition(e);
    lastX = pos.x;
    lastY = pos.y;
}

function draw(e) {
    if (!isDrawing) return;
    e.preventDefault();

    const pos = getPosition(e);

    ctx.beginPath();
    ctx.moveTo(lastX, lastY);
    ctx.lineTo(pos.x, pos.y);
    ctx.stroke();

    lastX = pos.x;
    lastY = pos.y;
}

function stopDrawing() {
    isDrawing = false;
}

function handleTouchStart(e) {
    e.preventDefault();
    const touch = e.touches[0];
    startDrawing(touch);
}

function handleTouchMove(e) {
    e.preventDefault();
    const touch = e.touches[0];
    draw(touch);
}

function getPosition(e) {
    const rect = canvas.getBoundingClientRect();
    const scaleX = canvas.width / rect.width;
    const scaleY = canvas.height / rect.height;

    return {
        x: (e.clientX - rect.left) * scaleX,
        y: (e.clientY - rect.top) * scaleY
    };
}

function setTool(tool) {
    currentTool = tool;
    document.querySelectorAll('.tool-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.tool === tool);
    });

    if (tool === 'pen') {
        ctx.strokeStyle = '#000';
        ctx.globalCompositeOperation = 'source-over';
    } else {
        ctx.strokeStyle = '#fff';
        ctx.globalCompositeOperation = 'destination-out';
    }
    triggerHaptic('light');
}

function setBrushSize(size) {
    brushSize = parseInt(size);
    ctx.lineWidth = brushSize;
}

function clearCanvas() {
    ctx.fillStyle = '#fff';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.strokeStyle = currentTool === 'pen' ? '#000' : '#fff';
    triggerHaptic();
}

function solveDrawing() {
    currentImageBase64 = canvas.toDataURL('image/png').split(',')[1];
    solveProblem(true);
}

// ==================== SOLVE PROBLEM ====================
async function solveProblem(fromDrawing = false) {
    if (!currentImageBase64) {
        showToast('Please upload an image or draw a problem first', 'error');
        return;
    }

    const apiKey = localStorage.getItem('geminiApiKey');
    if (!apiKey) {
        showToast('API key not found. Please add your API key in settings.', 'error');
        return;
    }

    // Check quota
    if (!canMakeRequest()) {
        showToast('Daily quota exceeded. Please try again tomorrow or upgrade.', 'error');
        return;
    }

    // Show loading
    document.getElementById('uploadSection').style.display = 'none';
    document.getElementById('loadingSection').style.display = 'block';
    document.getElementById('resultsSection').style.display = 'none';
    document.getElementById('errorSection').style.display = 'none';
    triggerHaptic();
    mascotThinking(); // Start mascot thinking animation

    try {
        const result = await callGeminiAPI(apiKey, currentImageBase64);
        lastResult = result;
        recordUsage();
        displayResults(result);
        saveToHistory(result);
        updateStats(result.problemType, fromDrawing);
        checkAchievements();

        if (getSetting('voiceGuidance')) {
            speakSolution();
        }
    } catch (error) {
        displayError(error.message);
    }
}

// ==================== API CALL ====================
async function callGeminiAPI(apiKey, imageBase64) {
    const language = getSetting('language') || 'english';
    const includeAlternatives = getSetting('includeAlternatives') !== false;
    const includeExamples = getSetting('includeExamples') !== false;
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
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(requestBody)
        }
    );

    if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        if (response.status === 400) throw new Error('Invalid request. Please try a different image.');
        if (response.status === 401 || response.status === 403) throw new Error('Invalid API key. Please check your API key in settings.');
        if (response.status === 429) throw new Error('Too many requests. Please wait a moment and try again.');
        throw new Error(errorData.error?.message || 'Failed to analyze the image. Please try again.');
    }

    const data = await response.json();
    if (!data.candidates || !data.candidates[0]?.content?.parts?.[0]?.text) {
        throw new Error('No response from AI. Please try a clearer image.');
    }

    const responseText = data.candidates[0].content.parts[0].text;
    let cleanedText = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

    try {
        return JSON.parse(cleanedText);
    } catch (e) {
        console.error('Failed to parse response:', cleanedText);
        throw new Error('Failed to parse the solution. Please try again.');
    }
}

// ==================== DISPLAY RESULTS ====================
function displayResults(result) {
    document.getElementById('loadingSection').style.display = 'none';
    document.getElementById('resultsSection').style.display = 'block';

    // Mascot celebration!
    mascotStopThinking();
    mascotCelebrate();

    // Recognized Text
    document.getElementById('recognizedText').textContent = result.recognizedText || 'Could not recognize';
    document.getElementById('problemType').textContent = result.problemType || 'Unknown';

    // Confidence Badge
    const confidenceBadge = document.getElementById('confidenceBadge');
    const confidence = result.confidence || 0;
    confidenceBadge.textContent = `${Math.round(confidence * 100)}% confident`;
    confidenceBadge.className = 'confidence-badge' + (confidence < 0.5 ? ' low' : confidence < 0.8 ? ' medium' : '');

    // Solution with animation
    const solutionText = document.getElementById('solutionText');
    solutionText.textContent = result.solution || 'No solution found';
    animateText(solutionText);

    // Steps with staggered animation
    const stepsContainer = document.getElementById('stepsContainer');
    stepsContainer.innerHTML = '';

    if (result.steps && result.steps.length > 0) {
        result.steps.forEach((step, index) => {
            const stepEl = document.createElement('div');
            stepEl.className = 'step-item';
            stepEl.style.animationDelay = `${index * 0.15}s`;
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
    }

    // Alternative Methods
    displayAlternatives(result.alternativeMethods);

    // Real World Examples
    displayExamples(result.realWorldExamples);

    // Graph Visualization
    displayGraph(result.graphData);

    // Scroll to results
    document.getElementById('resultsSection').scrollIntoView({ behavior: 'smooth' });
    triggerHaptic('success');
}

function displayAlternatives(alternatives) {
    const card = document.getElementById('alternativeMethodsCard');
    const container = document.getElementById('alternativesContainer');

    if (alternatives && alternatives.length > 0) {
        card.style.display = 'block';
        container.innerHTML = '';
        alternatives.forEach(method => {
            const el = document.createElement('div');
            el.className = 'alternative-item';
            el.innerHTML = `
                <div class="alternative-header">
                    <span class="alternative-name">${escapeHtml(method.name)}</span>
                    <span class="difficulty-badge ${method.difficulty}">${method.difficulty}</span>
                </div>
                <p>${escapeHtml(method.description)}</p>
            `;
            container.appendChild(el);
        });
    } else {
        card.style.display = 'none';
    }
}

function displayExamples(examples) {
    const card = document.getElementById('realWorldCard');
    const container = document.getElementById('examplesContainer');

    if (examples && examples.length > 0) {
        card.style.display = 'block';
        container.innerHTML = '';
        examples.forEach(example => {
            const el = document.createElement('div');
            el.className = 'example-item';
            el.innerHTML = `
                <div class="example-title">${escapeHtml(example.title)}</div>
                <p class="example-scenario">${escapeHtml(example.scenario)}</p>
                <p class="example-application">${escapeHtml(example.application)}</p>
            `;
            container.appendChild(el);
        });
    } else {
        card.style.display = 'none';
    }
}

function animateText(element) {
    const speed = getSetting('animationSpeed') || 'normal';
    const duration = speed === 'slow' ? '2s' : speed === 'fast' ? '0.5s' : '1s';
    element.style.animationDuration = duration;
    element.classList.add('animating');
    setTimeout(() => element.classList.remove('animating'), parseFloat(duration) * 1000);
}

function displayError(message) {
    document.getElementById('loadingSection').style.display = 'none';
    document.getElementById('errorSection').style.display = 'block';
    document.getElementById('errorMessage').textContent = message;
    triggerHaptic('error');
    mascotStopThinking();
    mascotSad(); // Mascot reacts to error
}

function newProblem() {
    clearImage();
    resetToUpload();
    switchTab('solve');
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

function resetToUpload() {
    document.getElementById('loadingSection').style.display = 'none';
    document.getElementById('resultsSection').style.display = 'none';
    document.getElementById('errorSection').style.display = 'none';
    document.getElementById('uploadSection').style.display = 'block';
}

// ==================== HISTORY ====================
function saveToHistory(result) {
    const history = JSON.parse(localStorage.getItem('problemHistory') || '[]');
    history.unshift({
        id: Date.now(),
        problem: result.recognizedText,
        solution: result.solution,
        type: result.problemType,
        date: new Date().toISOString(),
        steps: result.steps,
        graphData: result.graphData || null,
        favorite: false,
        notes: ''
    });

    // Keep only last 100 items
    if (history.length > 100) history.pop();

    localStorage.setItem('problemHistory', JSON.stringify(history));
}

function loadHistory() {
    let history = JSON.parse(localStorage.getItem('problemHistory') || '[]');
    const container = document.getElementById('historyList');
    const searchTerm = document.getElementById('historySearch')?.value?.toLowerCase() || '';

    // Apply search filter
    if (searchTerm) {
        history = history.filter(item =>
            (item.problem?.toLowerCase() || '').includes(searchTerm) ||
            (item.solution?.toLowerCase() || '').includes(searchTerm)
        );
    }

    // Apply type filter
    if (currentFilter !== 'all') {
        if (currentFilter === 'favorites') {
            history = history.filter(item => item.favorite);
        } else {
            history = history.filter(item => item.type?.toLowerCase() === currentFilter);
        }
    }

    // Apply sort
    history = sortHistoryArray(history, currentSort);

    if (history.length === 0) {
        const message = searchTerm || currentFilter !== 'all'
            ? 'No problems match your filters.'
            : 'No problems solved yet. Start solving to build your history!';
        container.innerHTML = `<p class="empty-state">${message}</p>`;
        return;
    }

    container.innerHTML = '';
    history.forEach(item => {
        const el = document.createElement('div');
        el.className = 'history-item';
        el.innerHTML = `
            <div class="history-item-header">
                <div class="history-item-main" onclick="viewHistoryItem(${item.id})">
                    <span class="history-problem">${escapeHtml(item.problem?.substring(0, 40) || 'Unknown')}${(item.problem?.length || 0) > 40 ? '...' : ''}</span>
                    <div class="history-meta">
                        <span class="history-date">${formatDate(item.date)}</span>
                        ${item.type ? `<span class="history-type-badge">${item.type}</span>` : ''}
                    </div>
                </div>
                <div class="history-actions">
                    <button class="favorite-btn ${item.favorite ? 'active' : ''}" onclick="toggleFavorite(${item.id}, event)" title="Favorite">
                        ${item.favorite ? '⭐' : '☆'}
                    </button>
                    <button class="add-note-btn" onclick="addNote(${item.id}, event)" title="Add note">
                        📝
                    </button>
                </div>
            </div>
            <div class="history-solution" onclick="viewHistoryItem(${item.id})">= ${escapeHtml(item.solution || 'N/A')}</div>
            ${item.notes ? `<div class="history-notes">${escapeHtml(item.notes)}</div>` : ''}
        `;
        container.appendChild(el);
    });
}

function sortHistoryArray(history, sortType) {
    switch (sortType) {
        case 'oldest':
            return [...history].sort((a, b) => new Date(a.date) - new Date(b.date));
        case 'alphabetical':
            return [...history].sort((a, b) => (a.problem || '').localeCompare(b.problem || ''));
        case 'newest':
        default:
            return [...history].sort((a, b) => new Date(b.date) - new Date(a.date));
    }
}

function setFilter(filter) {
    currentFilter = filter;
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.filter === filter);
    });
    loadHistory();
    triggerHaptic('light');
}

function sortHistory() {
    currentSort = document.getElementById('historySort').value;
    loadHistory();
}

function filterHistory() {
    loadHistory();
}

function toggleFavorite(itemId, event) {
    event.stopPropagation();
    const history = JSON.parse(localStorage.getItem('problemHistory') || '[]');
    const item = history.find(h => h.id === itemId);
    if (item) {
        item.favorite = !item.favorite;
        localStorage.setItem('problemHistory', JSON.stringify(history));
        loadHistory();
        showToast(item.favorite ? 'Added to favorites' : 'Removed from favorites', 'success');
        triggerHaptic();
    }
}

function addNote(itemId, event) {
    event.stopPropagation();
    const history = JSON.parse(localStorage.getItem('problemHistory') || '[]');
    const item = history.find(h => h.id === itemId);
    if (item) {
        const note = prompt('Add a note for this problem:', item.notes || '');
        if (note !== null) {
            item.notes = note;
            localStorage.setItem('problemHistory', JSON.stringify(history));
            loadHistory();
            showToast('Note saved', 'success');
        }
    }
}

function viewHistoryItem(itemId) {
    const history = JSON.parse(localStorage.getItem('problemHistory') || '[]');
    const item = history.find(h => h.id === itemId);
    if (item) {
        lastResult = item;
        displayResults({
            recognizedText: item.problem,
            solution: item.solution,
            problemType: item.type,
            confidence: 1,
            steps: item.steps || [],
            graphData: item.graphData
        });
        switchTab('solve');
    }
}

function clearHistory() {
    if (confirm('Are you sure you want to clear all history?')) {
        localStorage.setItem('problemHistory', '[]');
        loadHistory();
        showToast('History cleared', 'success');
        triggerHaptic();
    }
}

function formatDate(dateStr) {
    const date = new Date(dateStr);
    const now = new Date();
    const diff = now - date;

    if (diff < 60000) return 'Just now';
    if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`;
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`;
    if (diff < 604800000) return `${Math.floor(diff / 86400000)}d ago`;
    return date.toLocaleDateString();
}

// ==================== TYPE INPUT ====================
function insertSymbol(symbol) {
    const textarea = document.getElementById('typedProblem');
    const start = textarea.selectionStart;
    const end = textarea.selectionEnd;
    const text = textarea.value;
    textarea.value = text.substring(0, start) + symbol + text.substring(end);
    textarea.selectionStart = textarea.selectionEnd = start + symbol.length;
    textarea.focus();
    triggerHaptic('light');
}

async function solveTypedProblem() {
    const problem = document.getElementById('typedProblem').value.trim();
    if (!problem) {
        showToast('Please enter a math problem', 'error');
        return;
    }

    const apiKey = localStorage.getItem('geminiApiKey');
    if (!apiKey) {
        showToast('API key not found. Please add your API key in settings.', 'error');
        return;
    }

    if (!canMakeRequest()) {
        showToast('Daily quota exceeded. Please try again tomorrow or upgrade.', 'error');
        return;
    }

    // Switch to solve tab and show loading
    switchTab('solve');
    document.getElementById('uploadSection').style.display = 'none';
    document.getElementById('loadingSection').style.display = 'block';
    document.getElementById('resultsSection').style.display = 'none';
    document.getElementById('errorSection').style.display = 'none';
    triggerHaptic();

    try {
        const result = await callGeminiTextAPI(apiKey, problem);
        lastResult = result;
        recordUsage();
        displayResults(result);
        saveToHistory(result);
        updateStats(result.problemType, false);
        checkAchievements();

        if (getSetting('voiceGuidance')) {
            speakSolution();
        }
    } catch (error) {
        displayError(error.message);
    }
}

async function callGeminiTextAPI(apiKey, problem) {
    const language = getSetting('language') || 'english';
    const includeAlternatives = getSetting('includeAlternatives') !== false;
    const includeExamples = getSetting('includeExamples') !== false;
    const languageName = language === 'greek' ? 'Greek' : 'English';

    const prompt = `You are an expert math tutor. Solve the following math problem. Respond in ${languageName}.

Problem: ${problem}

Return a JSON object with this exact structure:
{
    "recognizedText": "${problem}",
    "problemType": "algebra|geometry|calculus|arithmetic|trigonometry|statistics|unknown",
    "solution": "the final answer",
    "confidence": 1.0,
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
    ]` : ''},
    "graphData": {
        "type": "line|none",
        "points": [{"x": 0, "y": 0}],
        "expression": "y = x",
        "xMin": -10,
        "xMax": 10
    }
}

If the problem involves a function that can be graphed (like y = 2x + 1, or f(x) = x²), include graphData. Otherwise set graphData.type to "none".

IMPORTANT: Return ONLY valid JSON, no markdown code blocks.`;

    const requestBody = {
        contents: [{
            parts: [{ text: prompt }]
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
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(requestBody)
        }
    );

    if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.error?.message || 'Failed to solve the problem. Please try again.');
    }

    const data = await response.json();
    if (!data.candidates || !data.candidates[0]?.content?.parts?.[0]?.text) {
        throw new Error('No response from AI. Please try again.');
    }

    const responseText = data.candidates[0].content.parts[0].text;
    let cleanedText = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

    try {
        return JSON.parse(cleanedText);
    } catch (e) {
        console.error('Failed to parse response:', cleanedText);
        throw new Error('Failed to parse the solution. Please try again.');
    }
}

// ==================== GRAPH VISUALIZATION ====================
function displayGraph(graphData) {
    const graphCard = document.getElementById('graphCard');
    const canvas = document.getElementById('mathGraph');

    if (!graphData || graphData.type === 'none' || !graphData.points || graphData.points.length === 0) {
        graphCard.style.display = 'none';
        return;
    }

    graphCard.style.display = 'block';

    // Destroy existing chart if any
    if (mathChart) {
        mathChart.destroy();
    }

    const ctx = canvas.getContext('2d');
    const isDark = document.body.getAttribute('data-theme') === 'dark';

    // Generate points if we have an expression
    let points = graphData.points;
    if (graphData.expression && graphData.xMin !== undefined && graphData.xMax !== undefined) {
        points = generateGraphPoints(graphData.expression, graphData.xMin, graphData.xMax);
    }

    mathChart = new Chart(ctx, {
        type: 'line',
        data: {
            datasets: [{
                label: graphData.expression || 'Function',
                data: points.map(p => ({ x: p.x, y: p.y })),
                borderColor: '#FF9500',
                backgroundColor: 'rgba(255, 149, 0, 0.1)',
                borderWidth: 2,
                pointRadius: 0,
                fill: true,
                tension: 0.4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                x: {
                    type: 'linear',
                    position: 'center',
                    grid: {
                        color: isDark ? '#3A3A3C' : '#E5E5EA'
                    },
                    ticks: {
                        color: isDark ? '#8E8E93' : '#1C1C1E'
                    }
                },
                y: {
                    type: 'linear',
                    position: 'center',
                    grid: {
                        color: isDark ? '#3A3A3C' : '#E5E5EA'
                    },
                    ticks: {
                        color: isDark ? '#8E8E93' : '#1C1C1E'
                    }
                }
            },
            plugins: {
                legend: {
                    display: true,
                    labels: {
                        color: isDark ? '#FFFFFF' : '#1C1C1E'
                    }
                }
            }
        }
    });
}

function generateGraphPoints(expression, xMin, xMax) {
    const points = [];
    const step = (xMax - xMin) / 100;

    // Simple expression parser for common functions
    const expr = expression.toLowerCase()
        .replace(/\^/g, '**')
        .replace(/y\s*=\s*/g, '')
        .replace(/f\(x\)\s*=\s*/g, '');

    for (let x = xMin; x <= xMax; x += step) {
        try {
            // Replace x with the current value
            const evalExpr = expr.replace(/x/g, `(${x})`);
            // Safe evaluation using Function constructor
            const y = Function(`'use strict'; return (${evalExpr})`)();
            if (isFinite(y)) {
                points.push({ x, y });
            }
        } catch (e) {
            // Skip invalid points
        }
    }

    return points;
}

// ==================== STATS & ACHIEVEMENTS ====================
function updateStats(problemType, fromDrawing = false) {
    const stats = JSON.parse(localStorage.getItem('userStats') || '{}');

    stats.totalSolved = (stats.totalSolved || 0) + 1;
    stats.byType = stats.byType || {};
    stats.byType[problemType] = (stats.byType[problemType] || 0) + 1;

    if (fromDrawing) {
        stats.drawSolved = (stats.drawSolved || 0) + 1;
    }

    // Update streak
    const today = new Date().toDateString();
    const lastSolve = stats.lastSolveDate;

    if (lastSolve !== today) {
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);

        if (lastSolve === yesterday.toDateString()) {
            stats.streak = (stats.streak || 0) + 1;
        } else if (lastSolve !== today) {
            stats.streak = 1;
        }
        stats.lastSolveDate = today;
    }

    // Check time-based achievements
    const hour = new Date().getHours();
    if (hour >= 0 && hour < 6) stats.earlyBird = true;
    if (hour >= 0 && hour < 5) stats.nightOwl = true;

    localStorage.setItem('userStats', JSON.stringify(stats));
    refreshStatsDisplay();
}

function refreshStatsDisplay() {
    const stats = JSON.parse(localStorage.getItem('userStats') || '{}');
    const unlockedCount = getUnlockedAchievements().length;

    document.getElementById('totalSolvedStat').textContent = stats.totalSolved || 0;
    document.getElementById('streakStat').textContent = stats.streak || 0;
    document.getElementById('badgesStat').textContent = unlockedCount;
}

function checkAchievements() {
    const stats = JSON.parse(localStorage.getItem('userStats') || '{}');
    const unlocked = JSON.parse(localStorage.getItem('unlockedAchievements') || '[]');

    ACHIEVEMENTS.forEach(achievement => {
        if (!unlocked.includes(achievement.id) && achievement.condition(stats)) {
            unlocked.push(achievement.id);
            localStorage.setItem('unlockedAchievements', JSON.stringify(unlocked));
            showAchievementPopup(achievement);
        }
    });

    refreshStatsDisplay();
}

function getUnlockedAchievements() {
    return JSON.parse(localStorage.getItem('unlockedAchievements') || '[]');
}

function showAchievementPopup(achievement) {
    const popup = document.getElementById('achievementPopup');
    document.getElementById('popupAchievementIcon').textContent = achievement.icon;
    document.getElementById('popupAchievementName').textContent = achievement.name;

    popup.style.display = 'block';
    triggerHaptic('success');

    setTimeout(() => {
        popup.style.display = 'none';
    }, 4000);
}

function showAchievements() {
    const modal = document.getElementById('achievementsModal');
    const stats = JSON.parse(localStorage.getItem('userStats') || '{}');
    const unlocked = getUnlockedAchievements();

    document.getElementById('unlockedBadges').textContent = unlocked.length;
    document.getElementById('currentStreak').textContent = stats.streak || 0;
    document.getElementById('totalProblems').textContent = stats.totalSolved || 0;

    const list = document.getElementById('achievementsList');
    list.innerHTML = '';

    ACHIEVEMENTS.forEach(achievement => {
        const isUnlocked = unlocked.includes(achievement.id);
        const el = document.createElement('div');
        el.className = `achievement-item ${isUnlocked ? '' : 'locked'}`;
        el.innerHTML = `
            <div class="achievement-badge">${isUnlocked ? achievement.icon : '🔒'}</div>
            <div class="achievement-details">
                <div class="achievement-name">${achievement.name}</div>
                <div class="achievement-desc">${achievement.description}</div>
            </div>
        `;
        list.appendChild(el);
    });

    modal.style.display = 'flex';
}

function closeAchievements() {
    document.getElementById('achievementsModal').style.display = 'none';
}

// ==================== USAGE & QUOTA ====================
function canMakeRequest() {
    const quota = getQuota();
    const usage = getUsage();
    return usage.daily < quota.daily;
}

function getQuota() {
    const tier = localStorage.getItem('userTier') || 'free';
    const customDaily = parseInt(localStorage.getItem('dailyLimit') || '0');

    const defaults = {
        free: { daily: 50, monthly: 1500 },
        premium: { daily: 1000, monthly: 30000 },
        unlimited: { daily: 999999, monthly: 999999 }
    };

    return {
        daily: customDaily || defaults[tier]?.daily || 50,
        monthly: defaults[tier]?.monthly || 1500
    };
}

function getUsage() {
    const usage = JSON.parse(localStorage.getItem('apiUsage') || '{}');
    const today = new Date().toDateString();
    const month = new Date().toISOString().slice(0, 7);

    // Reset if new day
    if (usage.lastDay !== today) {
        usage.daily = 0;
        usage.lastDay = today;
    }

    // Reset if new month
    if (usage.lastMonth !== month) {
        usage.monthly = 0;
        usage.lastMonth = month;
    }

    return {
        daily: usage.daily || 0,
        monthly: usage.monthly || 0,
        total: usage.total || 0
    };
}

function recordUsage() {
    const usage = JSON.parse(localStorage.getItem('apiUsage') || '{}');
    const today = new Date().toDateString();
    const month = new Date().toISOString().slice(0, 7);

    usage.daily = (usage.lastDay === today ? usage.daily : 0) + 1;
    usage.monthly = (usage.lastMonth === month ? usage.monthly : 0) + 1;
    usage.total = (usage.total || 0) + 1;
    usage.lastDay = today;
    usage.lastMonth = month;

    localStorage.setItem('apiUsage', JSON.stringify(usage));
    updateUsageDisplay();
}

function updateUsageDisplay() {
    const usage = getUsage();
    const quota = getQuota();
    const tier = localStorage.getItem('userTier') || 'free';

    document.getElementById('usageTier').textContent = tier.charAt(0).toUpperCase() + tier.slice(1);
    document.getElementById('usageCount').textContent = `${usage.daily}/${quota.daily} today`;
    document.getElementById('usageFill').style.width = `${Math.min((usage.daily / quota.daily) * 100, 100)}%`;

    document.getElementById('todayUsage').textContent = usage.daily;
    document.getElementById('monthlyUsage').textContent = usage.monthly;
}

// ==================== SETTINGS ====================
function showSettings() {
    const modal = document.getElementById('settingsModal');

    // Load current settings
    document.getElementById('settingsApiKey').value = localStorage.getItem('geminiApiKey') || '';
    document.getElementById('animationSpeed').value = getSetting('animationSpeed') || 'normal';
    document.getElementById('largeText').checked = getSetting('largeText') || false;
    document.getElementById('voiceGuidance').checked = getSetting('voiceGuidance') || false;
    document.getElementById('hapticFeedback').checked = getSetting('hapticFeedback') !== false;
    document.getElementById('includeAlternatives').checked = getSetting('includeAlternatives') !== false;
    document.getElementById('includeExamples').checked = getSetting('includeExamples') !== false;
    document.getElementById('privacyLevel').value = getSetting('privacyLevel') || 'standard';

    // Update language buttons
    const lang = getSetting('language') || 'english';
    document.querySelectorAll('.lang-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.lang === lang);
    });

    updateUsageDisplay();
    modal.style.display = 'flex';
}

function closeSettings() {
    document.getElementById('settingsModal').style.display = 'none';
    saveSettings();
}

function saveSettings() {
    setSetting('animationSpeed', document.getElementById('animationSpeed').value);
    setSetting('largeText', document.getElementById('largeText').checked);
    setSetting('voiceGuidance', document.getElementById('voiceGuidance').checked);
    setSetting('hapticFeedback', document.getElementById('hapticFeedback').checked);
    setSetting('includeAlternatives', document.getElementById('includeAlternatives').checked);
    setSetting('includeExamples', document.getElementById('includeExamples').checked);
    setSetting('privacyLevel', document.getElementById('privacyLevel').value);
}

function loadSettings() {
    if (getSetting('largeText')) {
        document.body.classList.add('large-text');
    }
}

function getSetting(key) {
    const settings = JSON.parse(localStorage.getItem('settings') || '{}');
    return settings[key];
}

function setSetting(key, value) {
    const settings = JSON.parse(localStorage.getItem('settings') || '{}');
    settings[key] = value;
    localStorage.setItem('settings', JSON.stringify(settings));
}

function toggleLargeText() {
    const enabled = document.getElementById('largeText').checked;
    document.body.classList.toggle('large-text', enabled);
    saveSettings();
}

function setLanguage(lang) {
    setSetting('language', lang);
    document.querySelectorAll('.lang-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.lang === lang);
    });
    triggerHaptic('light');
}

// ==================== ADMIN ====================
function setupAdminAccess() {
    const versionRow = document.getElementById('versionRow');
    if (!versionRow) return;

    let pressTimer = null;

    versionRow.addEventListener('mousedown', startAdminPress);
    versionRow.addEventListener('touchstart', startAdminPress);
    versionRow.addEventListener('mouseup', cancelAdminPress);
    versionRow.addEventListener('touchend', cancelAdminPress);
    versionRow.addEventListener('mouseleave', cancelAdminPress);

    function startAdminPress(e) {
        pressTimer = setTimeout(() => {
            showAdmin();
            triggerHaptic('success');
        }, 3000);
    }

    function cancelAdminPress() {
        clearTimeout(pressTimer);
    }
}

function showAdmin() {
    const adminKey = localStorage.getItem('adminKey');
    const modal = document.getElementById('adminModal');

    if (adminKey) {
        document.getElementById('adminAuth').style.display = 'none';
        document.getElementById('adminContent').style.display = 'block';
        loadAdminData();
    } else {
        document.getElementById('adminAuth').style.display = 'block';
        document.getElementById('adminContent').style.display = 'none';
    }

    modal.style.display = 'flex';
}

function closeAdmin() {
    document.getElementById('adminModal').style.display = 'none';
}

function authenticateAdmin() {
    const key = document.getElementById('adminKeyInput').value.trim();
    if (key) {
        localStorage.setItem('adminKey', key);
        document.getElementById('adminAuth').style.display = 'none';
        document.getElementById('adminContent').style.display = 'block';
        loadAdminData();
        triggerHaptic('success');
    } else {
        showToast('Please enter an admin key', 'error');
    }
}

function loadAdminData() {
    const usage = getUsage();
    document.getElementById('adminDailyUsage').textContent = usage.daily;
    document.getElementById('adminMonthlyUsage').textContent = usage.monthly;
    document.getElementById('adminTotalUsage').textContent = usage.total;

    document.getElementById('userTier').value = localStorage.getItem('userTier') || 'free';
    document.getElementById('dailyLimit').value = localStorage.getItem('dailyLimit') || getQuota().daily;
}

function updateQuota() {
    const tier = document.getElementById('userTier').value;
    const dailyLimit = document.getElementById('dailyLimit').value;

    localStorage.setItem('userTier', tier);
    localStorage.setItem('dailyLimit', dailyLimit);

    updateUsageDisplay();
    showToast('Quota updated', 'success');
}

function resetDailyUsage() {
    const usage = JSON.parse(localStorage.getItem('apiUsage') || '{}');
    usage.daily = 0;
    usage.lastDay = new Date().toDateString();
    localStorage.setItem('apiUsage', JSON.stringify(usage));
    loadAdminData();
    updateUsageDisplay();
    showToast('Daily usage reset', 'success');
}

function exportUsageReport() {
    const usage = getUsage();
    const stats = JSON.parse(localStorage.getItem('userStats') || '{}');
    const report = {
        usage,
        stats,
        exportDate: new Date().toISOString()
    };

    const blob = new Blob([JSON.stringify(report, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `lemon-math-report-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);

    showToast('Report exported', 'success');
}

// ==================== VOICE ====================
function speakSolution() {
    if (!lastResult) return;

    const text = `The solution is: ${lastResult.solution}`;
    speak(text);
}

function speakSteps() {
    if (!lastResult || !lastResult.steps) return;

    let text = 'Step by step solution: ';
    lastResult.steps.forEach((step, i) => {
        text += `Step ${i + 1}: ${step.title}. ${step.explanation}. `;
    });
    speak(text);
}

function speak(text) {
    if ('speechSynthesis' in window) {
        window.speechSynthesis.cancel();
        const utterance = new SpeechSynthesisUtterance(text);
        utterance.rate = 0.9;
        window.speechSynthesis.speak(utterance);
        showToast('Speaking...', 'info');
    } else {
        showToast('Speech not supported', 'error');
    }
}

// ==================== SHARE & COPY ====================
function copyResults() {
    if (!lastResult) return;

    const text = `Problem: ${lastResult.recognizedText || 'Unknown'}
Solution: ${lastResult.solution || 'Unknown'}

Steps:
${(lastResult.steps || []).map((s, i) => `${i + 1}. ${s.title}: ${s.explanation}\n   ${s.mathExpression}`).join('\n\n')}

Solved with Lemon Math 🍋`;

    navigator.clipboard.writeText(text).then(() => {
        showToast('Copied to clipboard!', 'success');
        triggerHaptic();
    }).catch(() => {
        showToast('Failed to copy', 'error');
    });
}

async function shareResults() {
    if (!lastResult) return;

    const shareData = {
        title: 'Lemon Math Solution',
        text: `Problem: ${lastResult.recognizedText}\nSolution: ${lastResult.solution}\n\nSolved with Lemon Math 🍋`,
    };

    if (navigator.share) {
        try {
            await navigator.share(shareData);
            showToast('Shared successfully!', 'success');
        } catch (err) {
            if (err.name !== 'AbortError') {
                copyResults();
            }
        }
    } else {
        copyResults();
    }
}

// ==================== DATA MANAGEMENT ====================
function exportData() {
    const data = {
        history: JSON.parse(localStorage.getItem('problemHistory') || '[]'),
        stats: JSON.parse(localStorage.getItem('userStats') || '{}'),
        achievements: JSON.parse(localStorage.getItem('unlockedAchievements') || '[]'),
        settings: JSON.parse(localStorage.getItem('settings') || '{}'),
        exportDate: new Date().toISOString()
    };

    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `lemon-math-data-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);

    showToast('Data exported', 'success');
}

function clearAllData() {
    if (confirm('Are you sure you want to clear ALL data? This cannot be undone.')) {
        const apiKey = localStorage.getItem('geminiApiKey');
        localStorage.clear();
        if (apiKey) localStorage.setItem('geminiApiKey', apiKey);

        showToast('All data cleared', 'success');
        location.reload();
    }
}

// ==================== UTILITIES ====================
function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function showToast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.innerHTML = `<span>${type === 'success' ? '✓' : type === 'error' ? '✗' : 'ℹ'}</span> ${message}`;
    container.appendChild(toast);

    setTimeout(() => {
        toast.style.animation = 'toastSlide 0.3s ease reverse forwards';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

function triggerHaptic(type = 'light') {
    if (!getSetting('hapticFeedback')) return;

    if ('vibrate' in navigator) {
        const patterns = {
            light: [10],
            success: [10, 50, 10],
            error: [50, 50, 50]
        };
        navigator.vibrate(patterns[type] || patterns.light);
    }
}

function mascotWave() {
    const mascot = document.querySelector('.mascot-mini');
    mascot.style.animation = 'wave 0.5s ease';
    setTimeout(() => mascot.style.animation = '', 500);
    triggerHaptic();
}

// ==================== ENHANCED MASCOT ANIMATIONS ====================
function mascotCelebrate() {
    const mascot = document.querySelector('.mascot-mini');
    if (!mascot) return;

    mascot.classList.add('celebrating');
    triggerHaptic('success');

    // Create confetti
    createConfetti();

    // Create emoji burst
    createEmojiBurst(['🎉', '✨', '🌟', '🎊'], mascot);

    setTimeout(() => {
        mascot.classList.remove('celebrating');
        mascot.classList.add('success-glow');
        setTimeout(() => mascot.classList.remove('success-glow'), 1000);
    }, 600);
}

function mascotThinking() {
    const mascot = document.querySelector('.mascot-mini');
    if (!mascot) return;

    mascot.classList.add('thinking');
}

function mascotStopThinking() {
    const mascot = document.querySelector('.mascot-mini');
    if (!mascot) return;

    mascot.classList.remove('thinking');
}

function mascotDance() {
    const mascot = document.querySelector('.mascot-mini');
    if (!mascot) return;

    mascot.classList.add('dancing');
    triggerHaptic('light');

    setTimeout(() => mascot.classList.remove('dancing'), 2400); // 3 dance cycles
}

function mascotSad() {
    const mascot = document.querySelector('.mascot-mini');
    if (!mascot) return;

    mascot.classList.add('sad');
    triggerHaptic('error');

    setTimeout(() => mascot.classList.remove('sad'), 2000);
}

function mascotJump() {
    const mascot = document.querySelector('.mascot-mini');
    if (!mascot) return;

    mascot.classList.add('jump');
    triggerHaptic('medium');

    setTimeout(() => mascot.classList.remove('jump'), 500);
}

function mascotHappyWiggle() {
    const mascot = document.querySelector('.mascot-mini');
    if (!mascot) return;

    mascot.classList.add('happy-wiggle');
    triggerHaptic('light');

    setTimeout(() => mascot.classList.remove('happy-wiggle'), 400);
}

function createConfetti() {
    const container = document.createElement('div');
    container.className = 'confetti-container';
    document.body.appendChild(container);

    const colors = ['#FEEF78', '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD', '#98D8C8'];

    for (let i = 0; i < 50; i++) {
        const confetti = document.createElement('div');
        confetti.className = 'confetti';
        confetti.style.left = Math.random() * 100 + '%';
        confetti.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)];
        confetti.style.animationDelay = Math.random() * 0.5 + 's';
        confetti.style.animationDuration = (2 + Math.random() * 2) + 's';

        // Random shapes
        const shapes = ['circle', 'square', 'triangle'];
        const shape = shapes[Math.floor(Math.random() * shapes.length)];
        if (shape === 'circle') {
            confetti.style.borderRadius = '50%';
        } else if (shape === 'triangle') {
            confetti.style.width = '0';
            confetti.style.height = '0';
            confetti.style.borderLeft = '5px solid transparent';
            confetti.style.borderRight = '5px solid transparent';
            confetti.style.borderBottom = '10px solid ' + colors[Math.floor(Math.random() * colors.length)];
            confetti.style.backgroundColor = 'transparent';
        }

        container.appendChild(confetti);
    }

    // Remove confetti container after animation
    setTimeout(() => container.remove(), 4000);
}

function createEmojiBurst(emojis, targetElement) {
    const rect = targetElement.getBoundingClientRect();
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;

    emojis.forEach((emoji, index) => {
        const burst = document.createElement('div');
        burst.className = 'emoji-burst';
        burst.textContent = emoji;
        burst.style.left = (centerX - 15 + (index - 1.5) * 30) + 'px';
        burst.style.top = centerY + 'px';
        burst.style.animationDelay = (index * 0.1) + 's';

        document.body.appendChild(burst);

        setTimeout(() => burst.remove(), 1100 + index * 100);
    });
}

// Random idle animations for the mascot
let mascotIdleInterval = null;

function startMascotIdleAnimations() {
    if (mascotIdleInterval) return;

    mascotIdleInterval = setInterval(() => {
        const animations = ['jump', 'happy-wiggle'];
        const randomAnim = animations[Math.floor(Math.random() * animations.length)];

        if (randomAnim === 'jump') {
            mascotJump();
        } else {
            mascotHappyWiggle();
        }
    }, 15000 + Math.random() * 10000); // Every 15-25 seconds
}

function stopMascotIdleAnimations() {
    if (mascotIdleInterval) {
        clearInterval(mascotIdleInterval);
        mascotIdleInterval = null;
    }
}

// Start idle animations when page loads
document.addEventListener('DOMContentLoaded', () => {
    startMascotIdleAnimations();
});

// ==================== EVENT LISTENERS ====================
document.getElementById('settingsModal')?.addEventListener('click', (e) => {
    if (e.target.id === 'settingsModal') closeSettings();
});

document.getElementById('achievementsModal')?.addEventListener('click', (e) => {
    if (e.target.id === 'achievementsModal') closeAchievements();
});

document.getElementById('adminModal')?.addEventListener('click', (e) => {
    if (e.target.id === 'adminModal') closeAdmin();
});

// Handle system theme changes
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
    if (localStorage.getItem('theme') === 'auto') {
        loadTheme();
    }
});

// Initialize on load
refreshStatsDisplay();
