# 🧬 miRNA-Seq Bioinformatics Pipeline (Academic Project)
> **A didactic implementation of Differential Expression Analysis (DEA) for small RNA-seq data**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Conda Environment](https://img.shields.io/badge/Conda-bioinfo__pipeline-blueviolet.svg)](#-setup-and-installation)
[![Python Version](https://img.shields.io/badge/Python-3.9-blue.svg)](https://www.python.org/)
[![R Version](https://img.shields.io/badge/R-4.2-blue.svg)](https://www.r-project.org/)

This project was developed as part of the **Bioinformatics** exam (Academic Year 2023/2024) at the **University of L'Aquila (UNIVAQ)**.

The bioinformatics pipeline automates the preprocessing, alignment, and differential statistical analysis of miRNA sequencing data. The workflow integrates quality control, UMI extraction, sequential double alignment (against the miRBase database and the hg38 reference genome), and the study of differential gene regulation (DEA) between different biological conditions.

---

## 🧬 Biological Context & Dataset
This pipeline was designed to analyze miRNAs expression in breast cancer patients. The cohort consists of three sample conditions:
- **BRCA**: Patients diagnosed with breast cancer who carry BRCA mutations.
- **non-BRCA**: Patients diagnosed with breast cancer who do not carry BRCA mutations.
- **Control**: Healthy individuals.

### Why 3 Run Folders?
In the `data/raw/` folder, the input FASTQ reads are organized into three subdirectories: **`Run1`**, **`Run2`**, and **`Run3`**. This structure mirrors the **three separate technical runs (sequencing batches)** in which the samples were processed. Organizing raw data by run is key to:
- Track and potentially adjust for **batch effects** during statistical analysis.
- Maintain experimental traceability of the samples.
- Process quality control (FastQC/MultiQC) and trimming on a per-batch basis before counts are consolidated.

---

## 🗺️ Pipeline Workflow
The flowchart below illustrates the sequential steps executed by the pipeline:

```mermaid
flowchart TD
    A[Raw FASTQ Reads] --> B(1. Quality Control: FastQC/MultiQC)
    B --> C(2. UMI Extraction & Trimming: Cutadapt/UMI-tools)
    C --> D(3. Post-Trimming Quality Control)
    D --> E(4. Reference Prep: Convert mature.fa U->T)
    E --> F(5. Sequential Alignment: miRBase Bowtie2)
    F --> G{Unaligned Reads?}
    G -- Yes --> H(6. Alignment: hg38 Bowtie2)
    G -- No --> I[miRNA Alignments]
    H --> J[Genomic Alignments]
    I & J --> K(7. Deduplication: UMI-tools dedup)
    K --> L(8. Count Tables Generation: featureCounts)
    L --> M(9. R DESeq2 Analysis: Heatmap & MA-plots)
```

---

## 📁 Directory Structure
The project is structured as follows to ensure proper organization of input and output files:

```text
.
├── annotation_files/         # Annotation files (.gff3)
├── data/                     # Folder for raw and intermediate data (ignored by git)
│   └── raw/
│       ├── Run1/
│       ├── Run2/
│       └── Run3/
├── reference/                # Indexes and references for alignment (ignored by git)
│   ├── hg38/
│   └── miRBase/
├── results/                  # Final generated results
│   ├── DEA/                  # Differential expression analysis (Heatmap, MA-plot, CSV)
│   └── counts/               # Merged count matrices
├── scripts/                  # Pipeline source code
└── pipeline.sh               # Main pipeline execution script
```

---

## 🛠️ Setup and Installation

### 1. Prerequisites
Ensure you have **Miniconda** or **Anaconda** installed on your system.

### 2. Environment Creation
The complete working environment containing all bioinformatics tools (Bowtie2, Samtools, Cutadapt, R, DESeq2, etc.) can be configured using a single command:

```bash
conda env create -f environment.yml
conda activate bioinfo_pipeline
```

### 3. Required Files
Before running the analysis, you need to acquire the following files:
* **Raw Data (FASTQ)**: place under `data/raw/` divided into their respective sub-directories `Run1`, `Run2`, `Run3`.
* **mature.fa**: download from [miRBase](https://www.mirbase.org/download/) and place in `reference/`.
* **GRCh38 Indexes**: Bowtie2 index files downloadable from [Bowtie2 Indexes](https://bowtie-bio.sourceforge.net/bowtie2/index.shtml) and placed under `reference/hg38/`.
* **hsa.gff3**: download from [miRBase](https://www.mirbase.org/download/) and place in `annotation_files/`.

---

## 🚀 Execution

You can run the entire pipeline using the main script:

```bash
bash pipeline.sh
```

Alternatively, you can run individual modules in order:

| Order | Script | Description |
| :---: | :--- | :--- |
| **1** | [quality_before_trimming.sh](scripts/quality_before_trimming.sh) | Initial quality control with FastQC and MultiQC |
| **2** | [trimming.sh](scripts/trimming.sh) | UMI extraction and adapter removal with Cutadapt |
| **3** | [quality_after_trimming.sh](scripts/quality_after_trimming.sh) | Post-trimming quality control |
| **4** | [convert.sh](scripts/convert.sh) | Conversion of `mature.fa` (from U to T) and human miRNA extraction |
| **5** | [align_to_miRBase.sh](scripts/align_to_miRBase.sh) | Bowtie2 alignment to miRBase and extraction of unaligned reads |
| **6** | [align_to_hg38.sh](scripts/align_to_hg38.sh) | hg38 alignment and BAM conversion/sorting |
| **7** | [qualimap.sh](scripts/qualimap.sh) | Alignment quality analysis with Qualimap |
| **8** | [rename.sh](scripts/rename.sh) | Automatic BAM renaming for downstream analysis |
| **9** | [miRBase_counts.sh](scripts/miRBase_counts.sh) | Count computation for miRBase alignment |
| **10**| [hg38_featurecounts.sh](scripts/hg38_featurecounts.sh) | Genomic count computation with featureCounts |
| **11**| [mergeCounts.py](scripts/mergeCounts.py) | Genomic and microRNA count merging |
| **12**| [dea.R](scripts/dea.R) | Statistical analysis with DESeq2 and plot generation |

---

## 📊 Results and Analysis

Upon execution, the pipeline dynamically creates a `results/` directory containing all outputs:
- **Quality Control Reports**: Located under `results/fastqc_reports/` and `results/multiqc_reports/`.
- **Alignment Statistics**: Reports generated under `results/alignment_reports/`.
- **Count Matrices**: Raw and merged counts under `results/counts/`.
- **Differential Expression Analysis (DEA)**: Output plots (heatmap, MA-plots) and differential CSV files saved under `results/DEA/`.

*Note: The `results/` folder is excluded from Git tracking to keep the repository lightweight. To view how the pipeline worked in our specific biological context, please refer to the complete report below.*

### Academic Material and Exam Reports
* 📄 **Complete Report**: [Report.pdf](Report.pdf) — Theoretical details, biological methodology, and discussion of results.

> [!WARNING]
> The biological findings, analysis, and conclusions presented in the academic report are for educational and pipeline-demonstration purposes only. They have not undergone formal peer-review or scientific validation, and should not be used as a direct reference or clinical truth.

---

## 👥 Authors
This project was carried out in collaboration by the following students:
* **Marco Di Francescantonio** (Repository owner)
* **Francisco Javier Macias Villaecija**
* **Lamin Chatty**

---

## 📚 References
1. **Biostars**: Bioinformatics resource thread. [https://www.biostars.org/p/9539851/](https://www.biostars.org/p/9539851/) (Accessed: 2024-07-02).
2. **Mitchell, P. S., Parkin, R. K., et al.** (2008). *Circulating microRNAs as stable blood-based markers for cancer detection*. Proceedings of the National Academy of Sciences, 105(30), 10513-10518.
3. **Neurobioinfo**: miRNA workflow. [https://github.com/neurobioinfo/miRNA_workflow](https://github.com/neurobioinfo/miRNA_workflow) (Accessed: 2024-07-02).
4. **Potla, P., Ali, S. A., & Kapoor, M.** (2021). *A bioinformatics approach to microRNA-sequencing analysis*. Osteoarthritis and Cartilage Open, 3(1), 100131.
5. **Xia, L., Guo, H., et al.** (2023). *Human circulating small non-coding RNA signature as a non-invasive biomarker in clinical diagnosis of acute myeloid leukaemia*. Theranostics, 13(4), 1289.

---

## ⚖️ License
This project is distributed under the MIT License. See the [LICENSE](LICENSE) file for details.
