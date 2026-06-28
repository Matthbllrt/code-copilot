const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Réserve de secours : dilemmes codés en dur si Gemini échoue
const FALLBACK_DILEMMAS = [
  {
    category: 'Absurde',
    question: 'Maudite pour l\'éternité, tu dois choisir ta malédiction...',
    choiceA: 'Éclats de rire incontrôlables pendant 5 min à chaque enterrement',
    choiceB: 'Crier « C\'EST FAUX ! » chaque fois que quelqu\'un ment',
  },
  {
    category: 'Humour noir',
    question: 'Seul(e) sur une île déserte, tu choisis...',
    choiceA: 'Un téléphone avec batterie infinie mais sans réseau',
    choiceB: 'Un réseau 5G parfait mais sans téléphone',
  },
  {
    category: 'Amour & Psycho',
    question: 'Tu découvres que ton/ta partenaire fait secrètement...',
    choiceA: 'Relit tous tes anciens messages en secret',
    choiceB: 'Note discrètement tous tes défauts dans un carnet',
  },
  {
    category: 'Moral',
    question: 'Dans une catastrophe, tu ne peux sauver qu\'un groupe...',
    choiceA: 'Ton meilleur(e) ami(e)',
    choiceB: '10 inconnus',
  },
  {
    category: 'Piquant',
    question: 'Le monde entier peut consulter en direct...',
    choiceA: 'Ton historique Google des 7 derniers jours',
    choiceB: 'Ton dernier brouillon de message jamais envoyé',
  },
  {
    category: 'Absurde',
    question: 'Pour le reste de ta vie, tu dois obligatoirement...',
    choiceA: 'Faire des bruits de voiture chaque fois que tu marches',
    choiceB: 'Narrer chaque action à la troisième personne à voix haute',
  },
  {
    category: 'Piquant',
    question: 'Tu dois montrer sans explication à tes collègues...',
    choiceA: 'Ton relevé bancaire du dernier mois',
    choiceB: 'Ton journal intime (ou notes privées)',
  },
  {
    category: 'Humour noir',
    question: 'Si tu devais rejouer ta vie, tu choisirais...',
    choiceA: 'Recommencer depuis la naissance avec tous tes souvenirs',
    choiceB: 'Continuer depuis aujourd\'hui mais dans un autre corps',
  },
  {
    category: 'Moral',
    question: 'Tu peux voyager dans le temps, mais...',
    choiceA: 'Seulement 5 minutes dans le passé, une fois par jour',
    choiceB: 'Seulement 5 minutes dans le futur, sans possibilité de retour',
  },
  {
    category: 'Amour & Psycho',
    question: 'Dans une relation, tu préfères être...',
    choiceA: 'Celui qui aime plus fort',
    choiceB: 'Celui qui aime un peu moins',
  },
  {
    category: 'Absurde',
    question: 'Pour te déplacer jusqu\'à la fin de ta vie, tu dois...',
    choiceA: 'Sautiller à cloche-pied en public',
    choiceB: 'Te déplacer à reculons partout',
  },
  {
    category: 'Piquant',
    question: 'Tu dois vivre avec la contrainte suivante...',
    choiceA: 'Ton visage rougit chaque fois que tu mens',
    choiceB: 'Tu dois chanter chaque phrase que tu veux communiquer',
  },
  {
    category: 'Moral',
    question: 'Tu peux mettre fin à une guerre mondiale, mais...',
    choiceA: 'Tu dois sacrifier 1 personne que tu aimes',
    choiceB: 'Tu perds tous tes souvenirs des 10 dernières années',
  },
  {
    category: 'Humour noir',
    question: 'Le diable te propose un marché : succès instantané si...',
    choiceA: 'Tu ne peux plus jamais manger ton plat préféré',
    choiceB: 'Tu dois travailler le double d\'heures pour toujours',
  },
];

const CATEGORIES = ['Absurde', 'Humour noir', 'Amour & Psycho', 'Piquant', 'Moral'];

function getTodayKey() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function pickFallbackDilemma(dateKey) {
  // Use date as a seed for deterministic selection
  const seed = dateKey.replace(/-/g, '').split('').reduce((a, c) => a + c.charCodeAt(0), 0);
  return FALLBACK_DILEMMAS[seed % FALLBACK_DILEMMAS.length];
}

async function generateWithGemini(category) {
  // Tente une génération via Gemini si GEMINI_API_KEY est configurée
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) return null;

  try {
    const { GoogleGenerativeAI } = require('@google/generative-ai');
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

    const prompt = `Tu es l'auteur des questions de l'app Cercle, ton ton est impertinent et drôle.
Génère un dilemme A/B de catégorie "${category}" en français.
Format JSON strict :
{
  "question": "La mise en situation (1-2 phrases max, style direct)",
  "choiceA": "Option A (courte, max 10 mots)",
  "choiceB": "Option B (courte, max 10 mots)"
}
Le dilemme doit être difficile à trancher, révélateur de personnalité. Pas de bonne réponse.`;

    const result = await model.generateContent(prompt);
    const text = result.response.text().trim();
    const json = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
    const parsed = JSON.parse(json);
    if (parsed.question && parsed.choiceA && parsed.choiceB) {
      return { category, ...parsed };
    }
  } catch (e) {
    console.warn('Gemini generation failed:', e.message);
  }
  return null;
}

// Fonction planifiée : génère le dilemme de demain chaque nuit à 1h (heure Paris)
exports.generateDailyDilemma = onSchedule(
  { schedule: '0 1 * * *', timeZone: 'Europe/Paris', region: 'europe-west1' },
  async () => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dateKey = tomorrow.toISOString().split('T')[0];

    const ref = db.collection('dilemmas').doc(dateKey);
    const existing = await ref.get();
    if (existing.exists) {
      console.log(`Dilemme pour ${dateKey} déjà existant, skip.`);
      return;
    }

    // Rotation des catégories
    const dayOfWeek = tomorrow.getDay();
    const category = CATEGORIES[dayOfWeek % CATEGORIES.length];

    let dilemma = await generateWithGemini(category);
    let source = 'gemini';
    if (!dilemma) {
      dilemma = pickFallbackDilemma(dateKey);
      source = 'fallback';
      console.log(`Gemini indisponible — utilisation du fallback pour ${dateKey}`);
    }

    await ref.set({
      category: dilemma.category,
      question: dilemma.question,
      choiceA: dilemma.choiceA,
      choiceB: dilemma.choiceB,
      votesA: 0,
      votesB: 0,
      source,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Dilemme créé pour ${dateKey}: [${source}] "${dilemma.question}"`);
  }
);

// Endpoint HTTP pour déclencher manuellement (test / amorçage)
exports.seedTodayDilemma = onRequest(
  { region: 'europe-west1' },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const dateKey = req.body.date || getTodayKey();
    const ref = db.collection('dilemmas').doc(dateKey);
    const existing = await ref.get();

    if (existing.exists && !req.body.force) {
      res.json({ status: 'exists', date: dateKey, data: existing.data() });
      return;
    }

    const dayOfWeek = new Date(dateKey + 'T12:00:00').getDay();
    const category = CATEGORIES[dayOfWeek % CATEGORIES.length];

    let dilemma = await generateWithGemini(category);
    let source = 'gemini';
    if (!dilemma) {
      dilemma = pickFallbackDilemma(dateKey);
      source = 'fallback';
    }

    const data = {
      category: dilemma.category,
      question: dilemma.question,
      choiceA: dilemma.choiceA,
      choiceB: dilemma.choiceB,
      votesA: 0,
      votesB: 0,
      source,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await ref.set(data);
    res.json({ status: 'created', date: dateKey, source, data });
  }
);
