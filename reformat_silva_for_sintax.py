#!/usr/bin/env python3
"""Reformat Emu's SILVA species_taxid.fasta into vsearch --sintax reference form.

vsearch --sintax needs headers of the form
    >id;tax=d:Domain,p:Phylum,c:Class,o:Order,f:Family,g:Genus,s:Genus_species;
Emu's headers are not in this form, for example:
    >1:emu-silva:1 ['dada2-silva_1 Bacteria;Proteobacteria;...;Pseudomonas;amygdali;']

For each record this script:
  - extracts the bracketed lineage,
  - splits it into up to seven ranks (domain -> species),
  - joins genus and species into a binomial (amygdali -> Pseudomonas_amygdali),
  - drops empty ranks,
  - drops non-informative species labels (phage, metagenome, uncultured, sp.),
  - replaces spaces, commas and semicolons in names with underscores.

Usage:
    python reformat_silva_for_sintax.py IN.fasta OUT.fasta [--limit N]

--limit N processes only the first N records (for a quick test).
Sequences are copied through unchanged; only headers are rewritten.
"""
import sys
import re
import argparse

RANK_PREFIXES = ["d", "p", "c", "o", "f", "g", "s"]          # domain .. species
# Species labels that carry no taxonomic information; drop the species rank.
NONINFORMATIVE = ("uncultured", "metagenome", "phage", "unidentified",
                  "unclassified", "sp.", "bacterium", "environmental")


def clean(name):
    """Replace spaces, commas and semicolons with underscores; collapse repeats."""
    name = re.sub(r"[ ,;]+", "_", name.strip())
    return name.strip("_")


def extract_lineage(header):
    """Return the semicolon-delimited lineage string from an Emu header, or None.

    Emu wraps the lineage in a bracketed, quoted field and prefixes it with an
    internal accession token, e.g.
        1:emu-silva:1 ['dada2-silva_1 Bacteria;Proteobacteria;...;amygdali;']
    We take the text inside the outermost [...], strip quotes, and keep the part
    that actually contains the ';'-delimited lineage.
    """
    m = re.search(r"\[(.*)\]", header)
    inside = m.group(1) if m else header
    inside = inside.strip().strip("'\"").strip()
    if ";" not in inside:
        return None
    # Drop a leading non-lineage token (the internal accession) if present:
    # the lineage is the whitespace-separated field that contains ';'.
    for field in inside.split(" ", 1)[::-1]:      # try the tail first, then whole
        if ";" in field:
            return field
    return inside


def to_sintax_tax(lineage):
    """Turn a ';'-delimited lineage into the d:..,p:..,..,s:.. tax string."""
    ranks = [r.strip() for r in lineage.split(";")]
    ranks = ranks[:len(RANK_PREFIXES)]            # domain..species, ignore extras
    ranks += [""] * (len(RANK_PREFIXES) - len(ranks))
    genus, species = ranks[5], ranks[6]

    # Non-informative species labels carry no information: drop the species rank.
    if species and any(tok in species.lower() for tok in NONINFORMATIVE):
        species = ""
    # Join genus + species into a binomial so 's:' is unambiguous.
    if species:
        species = f"{genus}_{species}" if genus else species

    ranks[6] = species
    parts = []
    for prefix, value in zip(RANK_PREFIXES, ranks):
        value = clean(value)
        if value:                                 # drop empty ranks
            parts.append(f"{prefix}:{value}")
    return ",".join(parts)


def reformat(in_path, out_path, limit=None):
    n_in = n_out = 0
    with open(in_path) as fin, open(out_path, "w") as fout:
        seq_id, tax, seq_lines, keep = None, None, [], False

        def flush():
            nonlocal n_out
            if seq_id is not None and keep:
                fout.write(f">{seq_id};tax={tax};\n")
                fout.writelines(seq_lines)
                n_out += 1

        for line in fin:
            if line.startswith(">"):
                flush()
                if limit is not None and n_in >= limit:
                    seq_id, keep = None, False
                    break
                n_in += 1
                header = line[1:].rstrip("\n")
                seq_id = header.split(" ", 1)[0].split("\t", 1)[0]
                lineage = extract_lineage(header)
                tax = to_sintax_tax(lineage) if lineage else ""
                keep = bool(tax)
                seq_lines = []
                if not keep:
                    sys.stderr.write(f"WARNING: no lineage parsed, dropped: {seq_id}\n")
            else:
                seq_lines.append(line)
        flush()

    sys.stderr.write(f"{n_in} records read, {n_out} written, {n_in - n_out} dropped\n")
    return n_in, n_out


def main():
    ap = argparse.ArgumentParser(description="Reformat Emu SILVA fasta for vsearch --sintax")
    ap.add_argument("in_fasta")
    ap.add_argument("out_fasta")
    ap.add_argument("--limit", type=int, default=None,
                    help="process only the first N records (for a quick test)")
    args = ap.parse_args()
    reformat(args.in_fasta, args.out_fasta, args.limit)


if __name__ == "__main__":
    main()
