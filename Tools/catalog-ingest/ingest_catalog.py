#!/usr/bin/env python3
"""Build catalog.sqlite from Gutenberg RDF + optional Open Library editions dump.

Run on a Mac/server, not on-device. Default output is Gutenberg-only rows with FTS5.

  python3 ingest_catalog.py --write-fixture ../../AudioBy/Resources/catalog.fixture.sqlite
  python3 ingest_catalog.py --gutenberg-rdf rdf-files.tar.zip --ol-dump ol_dump_editions.txt.gz -o catalog.sqlite
"""

from __future__ import annotations

import argparse
import gzip
import io
import json
import os
import re
import sqlite3
import tarfile
import unicodedata
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from typing import Iterable
from urllib.request import urlopen

GUTENBERG_RDF_URL = "https://www.gutenberg.org/cache/epub/feeds/rdf-files.tar.zip"
OL_DUMPS_PAGE = "https://openlibrary.org/developers/dumps"

NS = {
    "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    "dcterms": "http://purl.org/dc/terms/",
    "pgterms": "http://www.gutenberg.org/2009/pgterms/",
}

SCHEMA_SQL = """
CREATE TABLE books (
  id INTEGER PRIMARY KEY,
  gutenberg_id INTEGER,
  title TEXT NOT NULL,
  author TEXT,
  language TEXT,
  subjects TEXT,
  cover_url TEXT,
  has_librivox INTEGER NOT NULL DEFAULT 0,
  metadata_only INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_books_author ON books(author);
CREATE INDEX idx_books_language ON books(language);
CREATE INDEX idx_books_gutenberg ON books(gutenberg_id);
CREATE VIRTUAL TABLE books_fts USING fts5(
  title,
  author,
  subjects,
  content='books',
  content_rowid='id'
);
"""

FTS_TRIGGERS = """
CREATE TRIGGER books_ai AFTER INSERT ON books BEGIN
  INSERT INTO books_fts(rowid, title, author, subjects)
  VALUES (new.id, new.title, new.author, new.subjects);
END;
CREATE TRIGGER books_ad AFTER DELETE ON books BEGIN
  INSERT INTO books_fts(books_fts, rowid, title, author, subjects)
  VALUES('delete', old.id, old.title, old.author, old.subjects);
END;
CREATE TRIGGER books_au AFTER UPDATE ON books BEGIN
  INSERT INTO books_fts(books_fts, rowid, title, author, subjects)
  VALUES('delete', old.id, old.title, old.author, old.subjects);
  INSERT INTO books_fts(rowid, title, author, subjects)
  VALUES (new.id, new.title, new.author, new.subjects);
END;
"""

FIXTURE_BOOKS = [
    (11, "Alice's Adventures in Wonderland", "Lewis Carroll", "en", "Fiction,Fantasy,Children", 1),
    (84, "Frankenstein", "Mary Wollstonecraft Shelley", "en", "Fiction,Science Fiction,Horror", 1),
    (1342, "Pride and Prejudice", "Jane Austen", "en", "Fiction,Romance", 1),
    (2701, "Moby Dick; Or, The Whale", "Herman Melville", "en", "Fiction,Adventure", 1),
    (1661, "The Adventures of Sherlock Holmes", "Arthur Conan Doyle", "en", "Fiction,Mystery,Detective", 1),
    (98, "A Tale of Two Cities", "Charles Dickens", "en", "Fiction,History", 1),
    (76, "Adventures of Huckleberry Finn", "Mark Twain", "en", "Fiction,Adventure", 1),
    (74, "The Adventures of Tom Sawyer", "Mark Twain", "en", "Fiction,Adventure,Children", 1),
    (174, "The Picture of Dorian Gray", "Oscar Wilde", "en", "Fiction,Philosophy", 1),
    (345, "Dracula", "Bram Stoker", "en", "Fiction,Horror", 1),
    (46, "A Christmas Carol", "Charles Dickens", "en", "Fiction", 1),
    (1232, "The Prince", "Niccolò Machiavelli", "en", "Philosophy,Politics", 0),
    (1080, "A Modest Proposal", "Jonathan Swift", "en", "Satire", 0),
    (5200, "Metamorphosis", "Franz Kafka", "en", "Fiction", 1),
    (43, "The Strange Case of Dr. Jekyll and Mr. Hyde", "Robert Louis Stevenson", "en", "Fiction,Horror", 1),
    (16, "Peter Pan", "J. M. Barrie", "en", "Fiction,Children,Fantasy", 1),
    (2591, "Grimms' Fairy Tales", "Jacob Grimm and Wilhelm Grimm", "en", "Fiction,Children,Folklore", 1),
    (1260, "Jane Eyre", "Charlotte Brontë", "en", "Fiction,Romance", 1),
    (768, "Wuthering Heights", "Emily Brontë", "en", "Fiction,Romance", 1),
    (1400, "Great Expectations", "Charles Dickens", "en", "Fiction", 1),
    (2554, "Crime and Punishment", "Fyodor Dostoyevsky", "en", "Fiction,Philosophy", 1),
    (2600, "War and Peace", "Leo Tolstoy", "en", "Fiction,History,War", 1),
    (1399, "Anna Karenina", "Leo Tolstoy", "en", "Fiction,Romance", 1),
    (4300, "Ulysses", "James Joyce", "en", "Fiction", 0),
    (6130, "The Iliad", "Homer", "en", "Poetry,Classics,War", 1),
    (1727, "The Odyssey", "Homer", "en", "Poetry,Classics,Adventure", 1),
    (55, "The Wonderful Wizard of Oz", "L. Frank Baum", "en", "Fiction,Children,Fantasy", 1),
    (36, "The War of the Worlds", "H. G. Wells", "en", "Fiction,Science Fiction", 1),
    (35, "The Time Machine", "H. G. Wells", "en", "Fiction,Science Fiction", 1),
    (16328, "Beowulf", "Anonymous", "en", "Poetry,Classics", 1),
    (1184, "The Count of Monte Cristo", "Alexandre Dumas", "en", "Fiction,Adventure", 1),
    (1257, "The Three Musketeers", "Alexandre Dumas", "en", "Fiction,Adventure", 1),
    (996, "Don Quixote", "Miguel de Cervantes Saavedra", "en", "Fiction,Adventure,Classics", 1),
    (1497, "The Republic", "Plato", "en", "Philosophy", 0),
    (1998, "Thus Spake Zarathustra", "Friedrich Nietzsche", "en", "Philosophy", 0),
    (3207, "Leviathan", "Thomas Hobbes", "en", "Philosophy,Politics", 0),
    (3300, "An Inquiry into the Nature and Causes of the Wealth of Nations", "Adam Smith", "en", "Business,Economics", 0),
    (244, "A Study in Scarlet", "Arthur Conan Doyle", "en", "Fiction,Mystery,Detective", 1),
    (2852, "The Hound of the Baskervilles", "Arthur Conan Doyle", "en", "Fiction,Mystery", 1),
    (158, "Emma", "Jane Austen", "en", "Fiction,Romance", 1),
    (141, "Mansfield Park", "Jane Austen", "en", "Fiction,Romance", 1),
    (121, "Northanger Abbey", "Jane Austen", "en", "Fiction,Romance", 1),
    (105, "Persuasion", "Jane Austen", "en", "Fiction,Romance", 1),
    (161, "Sense and Sensibility", "Jane Austen", "en", "Fiction,Romance", 1),
    (25344, "The Scarlet Letter", "Nathaniel Hawthorne", "en", "Fiction", 1),
    (205, "Walden, and On The Duty Of Civil Disobedience", "Henry David Thoreau", "en", "Philosophy,Biography", 0),
    (1322, "Leaves of Grass", "Walt Whitman", "en", "Poetry", 0),
    (8799, "The Divine Comedy", "Dante Alighieri", "en", "Poetry,Classics", 0),
    (100, "The Complete Works of William Shakespeare", "William Shakespeare", "en", "Drama,Classics", 1),
    (1524, "Hamlet", "William Shakespeare", "en", "Drama,Classics", 1),
    (2265, "Hamlet, Prince of Denmark", "William Shakespeare", "en", "Drama,Classics", 1),
    (1112, "The Tragedy of Romeo and Juliet", "William Shakespeare", "en", "Drama,Romance", 1),
    (1533, "Macbeth", "William Shakespeare", "en", "Drama,Classics", 1),
    (2267, "The Merchant of Venice", "William Shakespeare", "en", "Drama", 1),
    (844, "The Importance of Being Earnest", "Oscar Wilde", "en", "Drama,Comedy", 1),
    (514, "Little Women", "Louisa May Alcott", "en", "Fiction,Children", 1),
    (45, "Anne of Green Gables", "L. M. Montgomery", "en", "Fiction,Children", 1),
    (120, "Treasure Island", "Robert Louis Stevenson", "en", "Fiction,Adventure,Children", 1),
    (829, "Gulliver's Travels", "Jonathan Swift", "en", "Fiction,Satire,Adventure", 1),
    (4217, "A Portrait of the Artist as a Young Man", "James Joyce", "en", "Fiction", 0),
    (2814, "Dubliners", "James Joyce", "en", "Fiction", 0),
    (730, "Oliver Twist", "Charles Dickens", "en", "Fiction", 1),
    (580, "The Pickwick Papers", "Charles Dickens", "en", "Fiction", 1),
    (766, "David Copperfield", "Charles Dickens", "en", "Fiction,Biography", 1),
    (1023, "Bleak House", "Charles Dickens", "en", "Fiction", 1),
    (967, "Tom Jones", "Henry Fielding", "en", "Fiction", 0),
    (408, "The Souls of Black Folk", "W. E. B. Du Bois", "en", "Biography,History,Philosophy", 0),
    (863, "The Mysterious Affair at Styles", "Agatha Christie", "en", "Fiction,Mystery,Detective", 1),
    (1155, "The Secret Adversary", "Agatha Christie", "en", "Fiction,Mystery", 1),
    (28520, "The Secret Garden", "Frances Hodgson Burnett", "en", "Fiction,Children", 1),
    (146, "A Little Princess", "Frances Hodgson Burnett", "en", "Fiction,Children", 1),
    (113, "The Secret Agent", "Joseph Conrad", "en", "Fiction", 0),
    (219, "Heart of Darkness", "Joseph Conrad", "en", "Fiction,Adventure", 1),
    (2500, "Siddhartha", "Hermann Hesse", "en", "Fiction,Philosophy", 0),
    (4363, "Beyond Good and Evil", "Friedrich Nietzsche", "en", "Philosophy", 0),
    (3600, "Essays of Michel de Montaigne", "Michel de Montaigne", "en", "Philosophy", 0),
    (61, "The Communist Manifesto", "Karl Marx and Friedrich Engels", "en", "Politics,Philosophy", 0),
    (11_001, "The Federalist Papers", "Alexander Hamilton, John Jay, and James Madison", "en", "Politics,History", 0),
    (1952, "The Yellow Wallpaper", "Charlotte Perkins Gilman", "en", "Fiction", 1),
    (64317, "The Great Gatsby", "F. Scott Fitzgerald", "en", "Fiction", 1),
]


def gutenberg_cover(gid: int) -> str:
    return f"https://www.gutenberg.org/cache/epub/{gid}/pg{gid}.cover.medium.jpg"


def normalize(text: str) -> str:
    text = unicodedata.normalize("NFKD", text or "")
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    text = text.lower()
    text = re.sub(r"[^a-z0-9\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def create_db(path: Path) -> sqlite3.Connection:
    if path.exists():
        path.unlink()
    path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(path))
    conn.execute("PRAGMA journal_mode=OFF")
    conn.execute("PRAGMA synchronous=OFF")
    conn.executescript(SCHEMA_SQL)
    conn.executescript(FTS_TRIGGERS)
    return conn


def insert_book(conn: sqlite3.Connection, **row) -> None:
    conn.execute(
        """
        INSERT INTO books (gutenberg_id, title, author, language, subjects, cover_url, has_librivox, metadata_only)
        VALUES (:gutenberg_id, :title, :author, :language, :subjects, :cover_url, :has_librivox, :metadata_only)
        """,
        row,
    )


def write_fixture(path: Path) -> None:
    conn = create_db(path)
    for gid, title, author, lang, subjects, has_lv in FIXTURE_BOOKS:
        insert_book(
            conn,
            gutenberg_id=gid,
            title=title,
            author=author,
            language=lang,
            subjects=subjects,
            cover_url=gutenberg_cover(gid),
            has_librivox=has_lv,
            metadata_only=0,
        )
    conn.commit()
    count = conn.execute("SELECT COUNT(*) FROM books").fetchone()[0]
    conn.close()
    print(f"Wrote fixture with {count} books to {path}")


def local_name(elem: ET.Element) -> str:
    if "}" in elem.tag:
        return elem.tag.split("}", 1)[1]
    return elem.tag


def parse_rdf_bytes(data: bytes) -> dict | None:
    try:
        root = ET.fromstring(data)
    except ET.ParseError:
        return None
    ebook = None
    for el in root.iter():
        if local_name(el) == "ebook":
            ebook = el
            break
    if ebook is None:
        return None
    about = ebook.attrib.get("{http://www.w3.org/1999/02/22-rdf-syntax-ns#}about", "")
    match = re.search(r"(\d+)$", about.replace("ebooks/", ""))
    if not match:
        return None
    gid = int(match.group(1))
    title = None
    author = None
    language = "en"
    subjects: list[str] = []
    for el in ebook.iter():
        name = local_name(el)
        text = (el.text or "").strip()
        if name == "title" and text and title is None:
            title = text.split("\n")[0].strip()
        elif name in {"name", "agent"} and text and author is None and name == "name":
            author = text
        elif name == "language" and text:
            language = text[:8]
        elif name in {"subject", "bookshelf"} and text:
            subjects.append(text)
    if author is None:
        for el in ebook.iter():
            if local_name(el) == "name" and (el.text or "").strip():
                author = el.text.strip()
                break
    if not title:
        return None
    return {
        "gutenberg_id": gid,
        "title": title,
        "author": author,
        "language": language,
        "subjects": ", ".join(subjects[:12]),
        "cover_url": gutenberg_cover(gid),
        "has_librivox": 0,
        "metadata_only": 0,
    }


def iter_gutenberg_rdf(archive_path: Path) -> Iterable[dict]:
    opener = zipfile.ZipFile if zipfile.is_zipfile(archive_path) else None
    if opener:
        with zipfile.ZipFile(archive_path) as zf:
            inner = None
            for name in zf.namelist():
                if name.endswith(".tar") or "rdf" in name.lower():
                    inner = name
                    if name.endswith(".tar"):
                        with zf.open(name) as tar_stream:
                            yield from iter_rdf_tar(tar_stream)
                        return
            # zip of rdf files directly
            for name in zf.namelist():
                if name.endswith(".rdf"):
                    parsed = parse_rdf_bytes(zf.read(name))
                    if parsed:
                        yield parsed
        return
    with archive_path.open("rb") as fh:
        yield from iter_rdf_tar(fh)


def iter_rdf_tar(stream) -> Iterable[dict]:
    with tarfile.open(fileobj=stream, mode="r|*") as tar:
        for member in tar:
            if not member.isfile() or not member.name.endswith(".rdf"):
                continue
            extracted = tar.extractfile(member)
            if extracted is None:
                continue
            parsed = parse_rdf_bytes(extracted.read())
            if parsed:
                yield parsed


def ol_key(title: str, author: str) -> str:
    return f"{normalize(title)}|{normalize(author).split(' ')[-1] if author else ''}"


def load_ol_covers(dump_path: Path, gutenberg_keys: dict[str, int], limit_lines: int | None = None) -> dict[int, str]:
    covers: dict[int, str] = {}
    opener = gzip.open if str(dump_path).endswith(".gz") else open
    processed = 0
    try:
        from rapidfuzz import fuzz
    except ImportError:
        fuzz = None
        print("rapidfuzz not installed; Open Library join will use exact normalized keys only.")

    with opener(dump_path, "rt", encoding="utf-8", errors="ignore") as fh:
        for line in fh:
            processed += 1
            if limit_lines and processed > limit_lines:
                break
            line = line.strip()
            if not line:
                continue
            # editions dump: type / key / revision / last_modified / json
            json_blob = line
            if "\t" in line:
                parts = line.split("\t")
                json_blob = parts[-1]
            try:
                rec = json.loads(json_blob)
            except json.JSONDecodeError:
                continue
            covers_ids = rec.get("covers") or []
            if not covers_ids:
                continue
            title = rec.get("title") or ""
            authors = rec.get("author_names") or []
            if not authors:
                authors = [a.get("key", "") if isinstance(a, dict) else str(a) for a in rec.get("authors") or []]
            author = authors[0] if authors else ""
            key = ol_key(title, str(author))
            gid = gutenberg_keys.get(key)
            if gid is None and fuzz is not None and title:
                # expensive fallback skipped in stream; exact key only for dump scale
                pass
            if gid is not None and gid not in covers:
                covers[gid] = f"https://covers.openlibrary.org/b/id/{covers_ids[0]}-M.jpg"
            if processed % 200000 == 0:
                print(f"  scanned {processed} Open Library lines, matched {len(covers)} covers")
    return covers


def apply_librivox_file(conn: sqlite3.Connection, path: Path) -> None:
    """Optional TSV/JSON list of title\\tauthor lines to fuzzy-flag has_librivox."""
    try:
        from rapidfuzz import fuzz
    except ImportError:
        print("rapidfuzz required for LibriVox matching; skipping.")
        return
    rows = conn.execute("SELECT id, title, author FROM books").fetchall()
    catalog = [(row[0], normalize(row[1] or ""), normalize(row[2] or "")) for row in rows]
    flagged = 0
    for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("{"):
            rec = json.loads(line)
            title, author = rec.get("title", ""), rec.get("author", "")
        else:
            parts = line.split("\t")
            title, author = parts[0], parts[1] if len(parts) > 1 else ""
        nt, na = normalize(title), normalize(author)
        best_id, best = None, 0
        for book_id, bt, ba in catalog:
            score = fuzz.ratio(nt, bt)
            if na and ba:
                score = (score + fuzz.ratio(na, ba)) / 2
            if score > best:
                best, best_id = score, book_id
        if best_id is not None and best >= 88:
            conn.execute("UPDATE books SET has_librivox = 1 WHERE id = ?", (best_id,))
            flagged += 1
    print(f"Flagged {flagged} LibriVox matches")


def ingest(args: argparse.Namespace) -> None:
    conn = create_db(Path(args.output))
    count = 0
    gutenberg_keys: dict[str, int] = {}
    print("Parsing Gutenberg RDF…")
    for book in iter_gutenberg_rdf(Path(args.gutenberg_rdf)):
        if args.english_only and (book.get("language") or "en")[:2] != "en":
            continue
        insert_book(conn, **book)
        count += 1
        gutenberg_keys[ol_key(book["title"], book.get("author") or "")] = book["gutenberg_id"]
        if count % 5000 == 0:
            conn.commit()
            print(f"  inserted {count} Gutenberg books")
    conn.commit()
    print(f"Inserted {count} Gutenberg books")

    if args.ol_dump:
        print("Joining Open Library covers (streaming)…")
        covers = load_ol_covers(Path(args.ol_dump), gutenberg_keys, args.ol_limit)
        for gid, url in covers.items():
            conn.execute("UPDATE books SET cover_url = ? WHERE gutenberg_id = ?", (url, gid))
        conn.commit()
        print(f"Updated {len(covers)} cover URLs from Open Library")

    if args.librivox_list:
        apply_librivox_file(conn, Path(args.librivox_list))
        conn.commit()

    remaining = conn.execute("SELECT COUNT(*) FROM books WHERE cover_url IS NULL OR cover_url = ''").fetchone()[0]
    if remaining:
        conn.execute(
            """
            UPDATE books SET cover_url = printf('https://www.gutenberg.org/cache/epub/%d/pg%d.cover.medium.jpg', gutenberg_id, gutenberg_id)
            WHERE gutenberg_id IS NOT NULL AND (cover_url IS NULL OR cover_url = '')
            """
        )
        conn.commit()
    conn.close()
    print(f"Wrote {args.output}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Build AudioBy catalog.sqlite")
    parser.add_argument("--write-fixture", metavar="PATH", help="Write the small bundled fixture database and exit")
    parser.add_argument("--gutenberg-rdf", help="Path to Gutenberg rdf-files.tar.zip (or .tar)")
    parser.add_argument("--ol-dump", help="Path to Open Library editions dump (.txt.gz)")
    parser.add_argument("--ol-limit", type=int, default=None, help="Optional max OL dump lines (debug)")
    parser.add_argument("--librivox-list", help="Optional TSV/JSONL of LibriVox titles for has_librivox")
    parser.add_argument("-o", "--output", default="catalog.sqlite")
    parser.add_argument("--english-only", action="store_true", default=True)
    parser.add_argument("--all-languages", action="store_true")
    args = parser.parse_args()
    if args.all_languages:
        args.english_only = False
    if args.write_fixture:
        write_fixture(Path(args.write_fixture))
        return
    if not args.gutenberg_rdf:
        parser.error("Provide --gutenberg-rdf or --write-fixture")
    ingest(args)


if __name__ == "__main__":
    main()
