# Security Policy

## Reporting a vulnerability

If you discover a security issue in this repository, especially accidental secret exposure, unsafe defaults or a configuration that could compromise a system using these files, please do not open a public issue containing sensitive details.

Instead, report it privately through GitHub's available private security reporting mechanisms when possible, or contact the repository maintainer through the contact information on the GitHub profile.

Please include enough information to reproduce and understand the issue, such as:

- affected file or module;
- expected and actual behaviour;
- potential impact;
- reproduction steps or proof of concept where appropriate;
- a suggested fix, if you have one.

## Scope

This repository contains a personal NixOS configuration intended as a reusable reference. Security reports related to the repository's own configuration, committed secrets material, unsafe permissions or reproducible configuration issues are in scope.

Vulnerabilities in upstream projects such as NixOS, Home Manager, Hyprland, sops-nix or other dependencies should generally be reported to their respective maintainers unless this repository introduces the issue through its own configuration.

## Secrets

Secrets in this repository are expected to be encrypted with SOPS/age. Private age keys and plaintext credentials must never be committed.
