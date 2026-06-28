// data.jsx — deck + character data for Inkpath
// Characters are all present in hanzi-writer-data@2.0.1.
// Each char: { c: glyph, meaning, reading } where reading is pinyin (zh) or on/kun (ja).

const DECKS = [
  {
    id: "jp-n5",
    lang: "ja",
    script: "Japanese",
    level: "JLPT N5",
    title: "First Kanji",
    blurb: "The everyday kanji behind days of the week, nature, and people.",
    accent: "sun",
    chars: [
      { c: "日", meaning: "sun · day", reading: "ニチ / ひ" },
      { c: "月", meaning: "moon · month", reading: "ゲツ / つき" },
      { c: "火", meaning: "fire", reading: "カ / ひ" },
      { c: "水", meaning: "water", reading: "スイ / みず" },
      { c: "木", meaning: "tree · wood", reading: "モク / き" },
      { c: "金", meaning: "gold · money", reading: "キン / かね" },
      { c: "土", meaning: "earth · soil", reading: "ド / つち" },
      { c: "山", meaning: "mountain", reading: "サン / やま" },
      { c: "川", meaning: "river", reading: "セン / かわ" },
      { c: "人", meaning: "person", reading: "ジン / ひと" },
    ],
  },
  {
    id: "zh-hsk1",
    lang: "zh",
    script: "Chinese",
    level: "HSK 1",
    title: "Essentials",
    blurb: "Your first ten characters — enough to greet someone and introduce yourself.",
    accent: "ink",
    chars: [
      { c: "你", meaning: "you", reading: "nǐ" },
      { c: "好", meaning: "good · well", reading: "hǎo" },
      { c: "我", meaning: "I · me", reading: "wǒ" },
      { c: "是", meaning: "to be", reading: "shì" },
      { c: "不", meaning: "not · no", reading: "bù" },
      { c: "中", meaning: "middle · center", reading: "zhōng" },
      { c: "国", meaning: "country", reading: "guó" },
      { c: "学", meaning: "to study", reading: "xué" },
      { c: "人", meaning: "person", reading: "rén" },
      { c: "大", meaning: "big · large", reading: "dà" },
    ],
  },
  {
    id: "numbers",
    lang: "both",
    script: "Chinese · Japanese",
    level: "Foundations",
    title: "Numbers 一–十",
    blurb: "One through ten — shared across both scripts, the perfect warm-up.",
    accent: "jade",
    chars: [
      { c: "一", meaning: "one", reading: "yī / いち" },
      { c: "二", meaning: "two", reading: "èr / に" },
      { c: "三", meaning: "three", reading: "sān / さん" },
      { c: "四", meaning: "four", reading: "sì / よん" },
      { c: "五", meaning: "five", reading: "wǔ / ご" },
      { c: "六", meaning: "six", reading: "liù / ろく" },
      { c: "七", meaning: "seven", reading: "qī / なな" },
      { c: "八", meaning: "eight", reading: "bā / はち" },
      { c: "九", meaning: "nine", reading: "jiǔ / きゅう" },
      { c: "十", meaning: "ten", reading: "shí / じゅう" },
    ],
  },
];

Object.assign(window, { DECKS });
