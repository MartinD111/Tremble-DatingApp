// Pep talk lines — cycled on every match reveal.
//
// Each entry has:
//   message  — the main pep-talk line (becomes the green italic subline)
//   note     — optional small caption underneath (mono / muted)
//
// A new message is picked at random for each reveal; the previous index is
// skipped so you never see the same line twice in a row.

const PEP_TALKS = [
  {
    message: "Go shoot your shot",
    note: "Please don't actually shoot anybody. Thank you",
  },
  {
    message: "You got this!",
    note: "We at Tremble believe that you believe in yourself",
  },
  {
    message: "What's the worst thing they can say?",
    note: "Best thing they can say is \"I'm Batman.\"",
  },
  {
    message: "You miss 100% of the shots you don't take",
    note: "Please don't actually shoot anybody. Thank you",
  },
  {
    message: "Life's too short to overthink it",
    note: "But not too short to avoid making it weird",
  },
  {
    message: "Take the leap",
    note: "Metaphorical leaps only. Knees are expensive",
  },
  {
    message: "Fortune favors the brave",
    note: "Brave people still respect boundaries",
  },
  {
    message: "Trust your rizz",
    note: "Confidence is attractive. Arson is not",
  },
  {
    message: "Stop rehearsing conversations in your head and just go for it",
    note: "They can't hear the imaginary version anyway",
  },
  {
    message: "Go create your rom-com moment",
    note: "Keep it cute and non-criminal",
  },
  {
    message: "The \u201Cwhat if\u201D will haunt you more than the rejection",
    note: "Unless you confess during their grandma's funeral. Timing matters",
  },
  {
    message: "Confidence looks good on you",
    note: "Overconfidence looks like a LinkedIn motivational post",
  },
  {
    message: "Make your move",
    note: "Preferably without dramatic background music",
  },
  {
    message: "Take the chance \u2014 your future self might thank you",
    note: "Your future self might also cringe. That's part of life",
  },
  {
    message: "Romantic risks build character",
    note: "So do restraining orders. Avoid those",
  },
  {
    message: "Worst case? You get rejected. Best case? Main character arc begins",
    note: "Please do not start narrating your life out loud",
  },
  {
    message: "Just be yourself",
    note: "Unless \u201Cyourself\u201D was planning a surprise ukulele performance",
  },
  {
    message: "Go flirt a little",
    note: "\u201CA little\u201D is the key phrase here",
  },
  {
    message: "Say hi \u2014 it's not a federal offense",
    note: "Unless you're trespassing. Then maybe leave first",
  },
  {
    message: "Your soulmate probably isn't going to materialize in your living room",
    note: "If they do, contact a physicist",
  },
  {
    message: "Take the risk. Great stories rarely start with \u201CI stayed home.\u201D",
    note: "Great court cases sometimes do, though",
  },
  {
    message: "Confidence is attractive. Panic monologues are less so",
    note: "Keep the TED Talk under 30 seconds",
  },
  {
    message: "Do it scared if you have to",
    note: "Just don't do it illegal while scared",
  },
  {
    message: "Make your intentions known",
    note: "Subtle hints are not a universal language",
  },
  {
    message: "Take the chance \u2014 life doesn't do reruns",
    note: "Except in your brain at 3 a.m",
  },
  {
    message: "You'll never know unless you try",
    note: "And yes, that includes making the first move",
  },
  {
    message: "If you feel the fear, that probably means it matters",
    note: "Or you just had too much caffeine \u2014 check both",
  },
  {
    message: "Go on, be a little courageous",
    note: "Not \u201Cjump off a cliff\u201D courageous. The other kind",
  },
  {
    message: "If it works, great. If it doesn't, you still get closure",
    note: "Closure is underrated and slightly bitter",
  },
];

// Pick a different pep talk than the one currently shown.
// `lastIndex` is the index just used; pass -1 on the first call.
function pickPepTalk(lastIndex) {
  if (PEP_TALKS.length <= 1) return { ...PEP_TALKS[0], index: 0 };
  let i;
  do {
    i = Math.floor(Math.random() * PEP_TALKS.length);
  } while (i === lastIndex);
  return { ...PEP_TALKS[i], index: i };
}

Object.assign(window, { PEP_TALKS, pickPepTalk });
