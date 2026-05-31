import 'dart:ui' show DisplayFeatureType, DisplayFeatureState;

import 'package:flutter/widgets.dart';

/// Form factor classification for foldable-aware layout.
///
/// The Tremble UI is designed for [standard] phones first. The other two
/// values exist purely to opt specific foldable surfaces into adapted layout:
///
/// - [compact]  — a small, near-square surface such as the Samsung Galaxy
///   Z Flip cover screen ("Flex Window"). Gets the two-item [CompactNavBar].
/// - [expanded] — a large surface such as the Z Fold inner screen or a tablet.
///   Gets max-width centered content so it does not stretch edge to edge.
/// - [standard] — every normal phone. Layout is UNCHANGED from before the
///   foldable work; this is the safe default and anything ambiguous lands here.
enum FormFactor { compact, standard, expanded }

/// Thresholds (logical pixels). Tuned so that ONLY genuine foldable surfaces
/// leave [FormFactor.standard]:
///
/// - Flip cover screens are tiny and roughly square (e.g. Z Flip5/6 Flex
///   Window ≈ 360×387 dp). We require BOTH a small height AND a narrow width
///   so a normal-but-short phone (or a split-screen pane) is not misread as a
///   cover screen. The smallest mainstream "real" phone, the iPhone SE, is
///   320×568 dp — its 568 dp height keeps it firmly in [standard].
/// - Expanded surfaces (Fold inner / tablets) have a large shortest side;
///   600 dp is the long-standing Material breakpoint for this.
@visibleForTesting
const double kCompactMaxHeight = 480.0;

@visibleForTesting
const double kCompactMaxWidth = 400.0;

@visibleForTesting
const double kExpandedMinShortestSide = 600.0;

/// Pure classifier — kept side-effect free so it can be unit tested without a
/// widget tree. Prefer [formFactorOf] inside widgets.
FormFactor classifyFormFactor(Size size) {
  final shortestSide = size.shortestSide;

  // Expanded wins first: a large shortest side is unambiguous (Fold inner /
  // tablet), regardless of orientation.
  if (shortestSide >= kExpandedMinShortestSide) {
    return FormFactor.expanded;
  }

  // Compact requires a genuinely small near-square surface. Both dimensions
  // must be small, so tall narrow phones never qualify.
  if (size.height < kCompactMaxHeight && size.width < kCompactMaxWidth) {
    return FormFactor.compact;
  }

  return FormFactor.standard;
}

/// Resolves the current [FormFactor] from the widget tree.
FormFactor formFactorOf(BuildContext context) =>
    classifyFormFactor(MediaQuery.sizeOf(context));

/// Max content width applied on [FormFactor.expanded] surfaces so the
/// phone-tuned layout stays centered and readable instead of stretching across
/// the full unfolded width. No effect on other form factors.
const double kExpandedContentMaxWidth = 560.0;

/// True when the display reports a fold/hinge separating it into regions
/// (an unfolded Z Fold). Used to keep interactive content out from under the
/// hinge. Safe on non-foldables — returns false when no such feature exists.
bool hasFoldingHinge(BuildContext context) {
  for (final feature in MediaQuery.of(context).displayFeatures) {
    final isHingeOrFold = feature.type == DisplayFeatureType.hinge ||
        feature.type == DisplayFeatureType.fold;
    final isSeparating =
        feature.state == DisplayFeatureState.postureHalfOpened ||
            feature.state == DisplayFeatureState.postureFlat;
    final hasArea = feature.bounds.width > 0 || feature.bounds.height > 0;
    if (isHingeOrFold && isSeparating && hasArea) {
      return true;
    }
  }
  return false;
}
