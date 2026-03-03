import json


def combine_japanese_data(kanjiapi_path, jmdict_path, output_path):
    # Load KanjiAPI data
    with open(kanjiapi_path, "r", encoding="utf-8") as f:
        kanji_data = json.load(f).get("kanjis", {})

    # Load JMDict data
    with open(jmdict_path, "r", encoding="utf-8") as f:
        jm_data = json.load(f)

    combined_items = []

    # 1. Process Vocabulary
    for word in jm_data.get("words", []):
        if not word.get("kanji"):
            continue

        subject = word["kanji"][0]["text"]
        furigana = word["kana"][0]["text"]
        meanings = [g["text"] for g in word["sense"][0]["gloss"]]

        combined_items.append(
            {
                "id": f"vocab-{word['id']}",
                "type": "vocabulary",
                "subject": subject,
                "furigana": furigana,
                "meanings": meanings,
                # For vocab, we store readings as a list of strings
                "readings": [furigana],
                "tags": ["Vocabulary"],
            }
        )

    # 2. Process Kanji with On/Kun distinction
    for char, info in kanji_data.items():
        # Create structured reading objects for Kanji
        structured_readings = []
        for r in info["on_readings"]:
            structured_readings.append({"value": r, "type": "on"})
        for r in info["kun_readings"]:
            structured_readings.append({"value": r, "type": "kun"})

        combined_items.append(
            {
                "id": f"kanji-{info.get('unicode', char)}",
                "type": "kanji",
                "subject": char,
                "furigana": info["kun_readings"][0] if info["kun_readings"] else "",
                "meanings": info["meanings"],
                "readings": structured_readings,  # List of objects for Kanji
                "tags": [f"JLPT-N{info['jlpt']}" if info["jlpt"] else "Kanji"],
            }
        )

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(combined_items, f, ensure_ascii=False, indent=2)


combine_japanese_data("kanjiapi_full.json", "jmdict-eng-3.6.2.json", "study_items.json")
