# Security Policy

## Scope
This project produces antibiotic dosing and stewardship recommendations. In addition to conventional software vulnerabilities, we treat the following as security issues:

* A dosing rule, CrCl breakpoint or PCT threshold that produces an unsafe recommendation.
* Any input that makes a function return a recommendation instead of an error when the input is clinically implausible.
* Any committed file that contains, or could re-identify, real patient data (PHI).

## Supported Versions
Only the latest commit on `main` is supported.

## Reporting a Vulnerability
Please **do not** open a public issue. Report privately using GitHub's
[private vulnerability reporting](https://github.com/dr-somashekhar/clinical-biomarker-stewardship/security/advisories/new),
including the inputs you used, the output you got, and the output you expected (with a reference such as the product label, if applicable).

You can expect an acknowledgement within 7 days.

## Data Handling
This repository must only ever contain synthetic data. If you find real patient data in the repository or its history, report it privately as above so it can be purged.
