import 'haggle.dart';
import 'thai_number.dart';

/// What a seller's reply to our offer amounts to.
enum ReplyKind { accept, refuse, counter, unclear }

class SellerReply {
  const SellerReply(this.kind, [this.amount]);

  final ReplyKind kind;

  /// The seller's new price, for [ReplyKind.counter].
  final double? amount;
}

/// Words a Thai seller uses to turn an offer down. Checked before
/// [acceptWordsTh], because "ไม่ได้" contains "ได้".
const refuseWordsTh = ['ไม่ได้', 'ลดไม่ได้', 'ไม่ลด', 'ไม่ไหว', 'ขาดทุน'];

/// Words a Thai seller uses to agree.
const acceptWordsTh = ['ได้', 'โอเค', 'ตกลง', 'เอา', 'โอเคร'];

/// Reads a seller's reply. A number makes it a counter, unless a refusal
/// word is there too ("150 ลดไม่ได้" keeps the price). Anything else is
/// unclear and the same offer is asked again.
SellerReply classifyReply(String thai) {
  final text = thai.trim();
  if (text.isEmpty) return const SellerReply(ReplyKind.unclear);
  if (refuseWordsTh.any(text.contains)) {
    return const SellerReply(ReplyKind.refuse);
  }
  final amount = findAmount(text);
  if (amount != null) return SellerReply(ReplyKind.counter, amount);
  if (acceptWordsTh.any(text.contains)) {
    return const SellerReply(ReplyKind.accept);
  }
  return const SellerReply(ReplyKind.unclear);
}

enum MoveKind { offer, accept, stop }

/// What to do after the seller's reply.
class NextMove {
  const NextMove(this.kind, {this.price});

  final MoveKind kind;

  /// [MoveKind.offer]: the next price to ask for. [MoveKind.accept]: the
  /// agreed price. [MoveKind.stop]: the seller's last price, to pay or leave.
  final double? price;
}

/// Our offers in total, including the first one; after that we stop
/// pushing and let the traveler decide.
const maxOffers = 3;

/// One haggle over one item: every price the seller said and every price we
/// offered, so each new reply is judged against the whole exchange.
class HaggleHistory {
  HaggleHistory({
    required this.item,
    required this.firstAsk,
    required this.firstOffer,
  }) : _sellerPrices = [firstAsk],
       _ourOffers = [firstOffer];

  final MarketItem item;
  final double firstAsk;
  final double firstOffer;
  final List<double> _sellerPrices;
  final List<double> _ourOffers;

  List<double> get sellerPrices => List.unmodifiable(_sellerPrices);
  List<double> get ourOffers => List.unmodifiable(_ourOffers);
  double get sellerPrice => _sellerPrices.last;
  double get lastOffer => _ourOffers.last;

  NextMove respond(SellerReply reply) {
    switch (reply.kind) {
      case ReplyKind.unclear:
        return NextMove(MoveKind.offer, price: lastOffer);
      case ReplyKind.accept:
        return NextMove(MoveKind.accept, price: lastOffer);
      case ReplyKind.refuse:
        return _nextOffer();
      case ReplyKind.counter:
        final p = reply.amount!;
        // At or below what we asked for, or now a usual price: take it.
        if (p <= lastOffer || p <= item.high) {
          return NextMove(MoveKind.accept, price: p);
        }
        // The same price again (or higher) is a refusal.
        if (p >= sellerPrice) return _nextOffer();
        _sellerPrices.add(p);
        return _nextOffer();
    }
  }

  /// Meets the seller halfway, in whole steps, while there is room.
  NextMove _nextOffer() {
    if (_ourOffers.length >= maxOffers) {
      return NextMove(MoveKind.stop, price: sellerPrice);
    }
    final middle = (lastOffer + sellerPrice) / 2;
    final offer = (middle / counterOfferStep).floor() * counterOfferStep;
    if (offer <= lastOffer || offer >= sellerPrice) {
      return NextMove(MoveKind.stop, price: sellerPrice);
    }
    _ourOffers.add(offer.toDouble());
    return NextMove(MoveKind.offer, price: offer.toDouble());
  }
}
