nextflow.enable.dsl=2

// ===========================
// PARAMS
// ===========================

// ON/OFF modules
params.enable_rgi     = true
params.enable_bacmet  = true
params.enable_barrnap = true
params.enable_plasmid = true
params.enable_prokka  = true
params.test = false
// ===========================
// CHANNELS
// ===========================
Channel
  .fromPath(
    params.input.endsWith('/') || params.input ==~ /.*\/$/ 
      ? "${params.input}/*.{fa,fasta,fna}"
      : params.input,
    checkIfExists: true
  )
  .ifEmpty { 
    error "❌ No file FASTA (.fa/.fasta/.fna) found in: ${params.input}" 
  }
  .set { ch_fasta }

// Channel for Prokka
def ch_prokka = ch_fasta

// ===========================
// PROCESSES
// ===========================

// ---- RGI (ARGs) ----
process ARG_ANNOT {
  tag { file(infile).baseName }
  publishDir "${params.outdir}/rgi", mode: 'copy', overwrite: true

  input:
    path infile

  output:
    path "*_rgi.*"

  when:
    params.enable_rgi

  script:
  """
  mkdir -p work_in
  cp $infile work_in/
  TEST_MODE=${params.test:-false} \
  bash ${projectDir}/bin/ARG_annotation.sh \\
    --input work_in \\
    --outdir . \\
    --card ${params.carddir} \\
    --threads ${params.threads} 
  """
}

// ---- BacMet (MRGs, auto-download) ----
process BACMET_ANNOT {
  tag { file(infile).baseName }
  publishDir "${params.outdir}/bacmet", mode: 'copy', overwrite: true

  input:
    path infile

  output:
    path "*_bacmet.tsv"

  when:
    params.enable_bacmet

  script:
  """
  mkdir -p work_in
  cp $infile work_in/
  bash ${projectDir}/bin/BacMet_annotation.sh \\
    --input work_in \\
    --outdir . \\
    --threads ${params.threads}
  """
}

// ---- Barrnap (16S / rRNA) ----
process BARRNAP_16S {
  tag { file(infile).baseName }
  publishDir "${params.outdir}/barrnap", mode: 'copy', overwrite: true

  input:
    path infile

  output:
    path "*_rRNA.gff"
    path "*_16S.gff", optional: true

  when:
    params.enable_barrnap

  script:
  """
  mkdir -p work_in
  cp $infile work_in/
  bash ${projectDir}/bin/Barrnap_16S.sh \\
    --input work_in \\
    --outdir . \\
    --only-16S \\
    --threads ${params.threads}
  """
}

// ---- PlasmidFinder (auto-download) ----
process PLASMIDFINDER {
  tag { file(infile).baseName }
  publishDir "${params.outdir}/plasmidfinder", mode: 'copy', overwrite: true

  input:
    path infile

  output:
  path "*.tsv"
  path "*.txt", optional: true

  when:
    params.enable_plasmid

  script:
  """
  mkdir -p work_in
  cp $infile work_in/
  bash ${projectDir}/bin/Plasmid_annotation.sh \\
    --input work_in \\
    --outdir . \\
    --threads ${params.threads}
  """
}

// ---- Prokka (annotation + combine for KAAS) ----
process PROKKA_ANNOT {
  tag { file(infile).baseName }
  publishDir "${params.outdir}/prokka", mode: 'copy', overwrite: true

  input:
    path infile

  output:
  path "*.gff"
  path "*.faa"
  path "*.ffn"
  path "*.tsv", optional: true


  when:
    params.enable_prokka

  script:
  """
  mkdir -p work_in
  cp $infile work_in/
  bash ${projectDir}/bin/Prokka_annotation.sh \\
    --input work_in \\
    --outdir . \\
    --pattern "${infile.getName()}" \\
    --threads ${params.threads} 
  """
}

// ===========================
// WORKFLOW
// ===========================
workflow {
  main:
    if (params.enable_rgi)      ARG_ANNOT(ch_fasta)
    if (params.enable_bacmet)   BACMET_ANNOT(ch_fasta)
    if (params.enable_barrnap)  BARRNAP_16S(ch_fasta)
    if (params.enable_plasmid)  PLASMIDFINDER(ch_fasta)
    if (params.enable_prokka)   PROKKA_ANNOT(ch_prokka)
}

