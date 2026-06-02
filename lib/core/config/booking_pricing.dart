/// Flat per-session price charged for every therapy booking.
///
/// All booking flows (UI display, Firestore `amount` field, every payment
/// gateway) read from this constant. Individual therapists' `sessionPrice`
/// is informational only — what the customer actually pays is always this
/// value.
///
/// To change the price app-wide, update this number and (for Visa/Mastercard
/// only) the Freemius plan whose price must match — see
/// `freemiusProductionConfig.planIds['booking']` in
/// `lib/features/subscription/services/freemius_checkout_service.dart`.
const double kBookingFlatPriceUsd = 34.99;
const String kBookingFlatCurrency = 'USD';

/// Pre-formatted display string for the flat booking price.
/// Use everywhere the UI shows the per-session cost so the displayed amount
/// always matches what the customer is actually charged.
const String kBookingFlatPriceDisplay = '\$34.99';
