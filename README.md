# Embedded System for Suspicious Luggage Detection

This project presents an embedded system for detecting suspicious luggage in
CCTV surveillance footage, deployed on an NVIDIA Jetson Orin Nano. The pipeline
combines a fine-tuned YOLO26s object detection model with DeepSORT tracking and
custom spatio-temporal abandonment logic to identify luggage that has been
separated from its owner beyond a configurable temporal threshold, all running
in real-time through the NVIDIA DeepStream SDK.

A two-phase transfer learning strategy — training on COCO and Open Images
before fine-tuning on the domain-specific ABODA dataset — achieved a detection
mAP@0.5 of 0.859. End-to-end pipeline evaluation yielded an F1-score of 0.774
on in-domain ABODA sequences. The Jetson Orin Nano sustained real-time
processing at 86-90% GPU utilisation without thermal throttling, confirming the
viability of edge deployment for this workload.

## Repository Structure

This repository is organised into two submodules and a documentation directory:

- **[training/](training/)** — Docker-based training and ONNX export pipeline
  using Ultralytics YOLO. See the [training README](training/README.md) for
  setup and usage.
- **[inference/](inference/)** — DeepStream inference pipeline for the Jetson
  Orin Nano, including the abandonment detection logic and evaluation harness.
  See the [inference README](inference/README.md) for setup and usage.
- **[doc/](doc/)** — LaTeX source for the project report.

## Examples

[![ABODA Example](./doc/figures/aboda/attended.jpg)](https://github.com/user-attachments/assets/7787a3e2-3f0c-40a3-b475-4085c115394c)

[![AVSS 2007 Example](./doc/figures/avss/attended.jpg)](https://github.com/user-attachments/assets/a5be3db0-9406-424f-9150-44c7253e067d)

[![IITP20 Example](./doc/figures/iitp20/attended.jpg)](./doc/videos/IITP20_example.mp4)

## License

This project is licensed under the [MIT License](LICENSE).
