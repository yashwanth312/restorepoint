# 0007: Build the lab VMs by hand, keep the seed scripts in the repository

Date: 2026-11-14
Status: Accepted

## Context

Each lab VM needs data on it before backups mean anything: files, a database, web content, directory users. That data can be created by a script or typed in by hand. The project is meant to teach the method as well as produce a result, and the repository is public, so other people may want to reproduce the lab.

## Options

1. **Scripts only.** Fastest and reproducible, but the person who ran them could not explain what each step did.
2. **By hand only.** Every step is understood, but nobody else can reproduce the lab quickly.
3. **By hand first, with the equivalent scripts kept in the repository.**

## Decision

Option 3. The Linux VMs and the directory were built and seeded by hand, step by step, with each result recorded as evidence. The scripts in [`lab/`](../lab/) stay in the repository as the automated version of the same steps for anyone who clones it.

## Why

Understanding each step is the point of the project, and the baselines are measurements either way. The trade-off is that the scripts were syntax-checked but not run against the lab, so they are unproven until someone runs them on fresh VMs; the repository does not claim otherwise.
