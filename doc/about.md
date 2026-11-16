---
title: About Hyperbolic (v{{ VERSION }})
---

The **Hyperbolic Drawing Tool** is an interactive application designed to
construct, visualize, and explore geometric diagrams in the Poincarédisk model
of hyperbolic geometry.

It helps you perform classical straightedge-and-compass constructions adapted
to the Poincarédisk ($\mathbb{D} = \{z \in \mathbb{C} : |z| < 1\}$), where
Euclid's fifth postulate (the parallel postulate) does not hold.

This application is written in Dart with Flutter—the source code is available
on GitHub at [https://github.com/fredgc/hyperbolic][github].

Found a bug or have a feature request? [File an issue on GitHub][issues].

Other apps and drawing tools can be found at [www.gchouse.org][gchouse].

## Privacy and Data Retention

This program allows you to customize settings that are saved locally on your
device (using SharedPreferences / LocalStorage). No personal data is
collected.

On Android, local settings are deleted when you uninstall the app. On Web,
settings are deleted when you clear your browser's local application data.

Drawings may be downloaded to your local device or saved to your Google Drive
account. You may also load drawings shared by others, but no files are sent to
the `gchouse.org` server.

[gchouse]: https://www.gchouse.org [github]:
https://github.com/fredgc/hyperbolic [issues]:
https://github.com/fredgc/hyperbolic/issues
