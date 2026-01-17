// lib/screens/energy_market_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_profile.dart';
import '../models/trade_offer.dart';
import '../services/user_session.dart'; // Import UserSession

class EnergyMarketScreen extends StatefulWidget {
  static const routeName = '/energy-market';

  @override
  _EnergyMarketScreenState createState() => _EnergyMarketScreenState();
}

class _EnergyMarketScreenState extends State<EnergyMarketScreen> {
  final DatabaseReference _marketRef = FirebaseDatabase.instance.ref('market/sell_offers');
  final DatabaseReference _usersProfileRef = FirebaseDatabase.instance.ref('user_profiles');

  List<TradeOffer> _sellOffers = [];
  bool _isLoadingOffers = true;
  UserProfile? _currentUserProfile; // From arguments or fetched based on session
  String? _loggedInUsername;

  @override
  void initState() {
    super.initState();
    // Arguments are typically available after initState in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is UserProfile) {
      _currentUserProfile = args;
      _loggedInUsername = _currentUserProfile!.username;
    } else {
      _loadUsernameAndFetchProfileForMarket();
    }
    _fetchSellOffers();
  }

  Future<void> _loadUsernameAndFetchProfileForMarket() async {
    final username = await UserSession.getLoggedInUsername();
    if (username != null && mounted) {
      setState(() {
        _loggedInUsername = username;
      });
      await _fetchFreshProfile(username);
    }
  }

  Future<void> _fetchFreshProfile(String username) async {
      final snapshot = await _usersProfileRef.child(username).get();
      if (snapshot.exists && mounted) {
          setState(() {
              _currentUserProfile = UserProfile.fromSnapshot(snapshot);
          });
      }
  }

  void _fetchSellOffers() {
    _marketRef.onValue.listen((DatabaseEvent event) {
      final List<TradeOffer> loadedOffers = [];
      if (event.snapshot.exists && event.snapshot.value != null) {
        final Map<dynamic, dynamic> offersData = event.snapshot.value as Map<dynamic, dynamic>;
        offersData.forEach((offerId, offerData) {
           if (offerData is Map) {
             loadedOffers.add(TradeOffer.fromSnapshot(offerId, offerData));
           }
        });
        loadedOffers.sort((a, b) => a.pricePerKWh.compareTo(b.pricePerKWh));
      }
      if (mounted) {
        setState(() {
          _sellOffers = loadedOffers;
          _isLoadingOffers = false;
        });
      }
    }, onError: (error) {
      if(mounted) {
        print("Error fetching sell offers: $error");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not load market offers."), backgroundColor: Colors.red,));
        setState(() => _isLoadingOffers = false);
      }
    });
  }

  void _showPlaceOfferDialog() {
    if (_currentUserProfile == null || _loggedInUsername == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User profile not loaded. Please go back and try again."), backgroundColor: Colors.orange,));
      return;
    }
    if (_currentUserProfile!.energyBalanceKWh <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You have no energy to sell! Generate more first."), backgroundColor: Colors.orange,));
      return;
    }

    final _offerFormKey = GlobalKey<FormState>();
    double amountToSell = 0;
    double pricePerKWh = 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Place Energy Sell Offer'),
        content: Form(
          key: _offerFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Your Balance: ${_currentUserProfile!.energyBalanceKWh.toStringAsFixed(2)} kWh'),
                SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Amount to Sell (kWh)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter amount.';
                    final val = double.tryParse(value);
                    if (val == null || val <= 0) return 'Invalid amount.';
                    if (val > _currentUserProfile!.energyBalanceKWh) return 'Insufficient balance.';
                    return null;
                  },
                  onSaved: (value) => amountToSell = double.parse(value!),
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Price per kWh (e.g., 0.15)'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter price.';
                     final val = double.tryParse(value);
                    if (val == null || val <= 0) return 'Invalid price.';
                    return null;
                  },
                  onSaved: (value) => pricePerKWh = double.parse(value!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_offerFormKey.currentState!.validate()) {
                _offerFormKey.currentState!.save();
                final newOfferRef = _marketRef.push();
                final offer = TradeOffer(
                  offerId: newOfferRef.key!,
                  sellerUsername: _loggedInUsername!, // Use session username
                  amountKWh: amountToSell,
                  pricePerKWh: pricePerKWh,
                  poSWSellerScore: _currentUserProfile!.poSWScore,
                  timestamp: DateTime.now(),
                );
                try {
                  await newOfferRef.set(offer.toJson());
                  await _usersProfileRef.child(_loggedInUsername!).runTransaction((Object? mutableData){
                      if (mutableData == null) return Transaction.abort();
                      Map<String, dynamic> profile = Map<String, dynamic>.from(mutableData as Map);
                      double currentEnergy = (profile['energyBalanceKWh'] as num?)?.toDouble() ?? 0.0;
                      profile['energyBalanceKWh'] = currentEnergy - amountToSell;
                      return Transaction.success(profile);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Offer placed!'), backgroundColor: Colors.green,));
                   if(mounted) {
                       setState(() { // Optimistic update for current user's profile
                           _currentUserProfile!.energyBalanceKWh -= amountToSell;
                       });
                   }
                  Navigator.of(ctx).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to place offer: $e'), backgroundColor: Colors.red,));
                }
              }
            },
            child: Text('Place Offer'),
          ),
        ],
      ),
    );
  }

  void _buyOffer(TradeOffer offer) async {
    if (_currentUserProfile == null || _loggedInUsername == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Your profile is not loaded."), backgroundColor: Colors.orange));
      return;
    }
    if (_loggedInUsername == offer.sellerUsername) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You cannot buy your own offer.")));
      return;
    }

    if (mounted) setState(() { _isLoadingOffers = true; });

    try {
      final DatabaseReference offerRef = _marketRef.child(offer.offerId);
      final offerSnapshot = await offerRef.get();
      if (!offerSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Offer no longer available.'), backgroundColor: Colors.orange)
        );
        if (mounted) setState(() { _isLoadingOffers = false; });
        return;
      }

      // Buyer updates
      await _usersProfileRef.child(_loggedInUsername!).runTransaction((Object? mutableData) {
        if (mutableData == null) return Transaction.abort();
        Map<String, dynamic> profile = Map<String, dynamic>.from(mutableData as Map);
        double currentEnergy = (profile['energyBalanceKWh'] as num?)?.toDouble() ?? 0.0;
        profile['energyBalanceKWh'] = currentEnergy + offer.amountKWh;
        double currentPoSW = (profile['poSWScore'] as num?)?.toDouble() ?? 0.0;
        profile['poSWScore'] = currentPoSW + 0.02;
        return Transaction.success(profile);
      });

      // Seller updates (PoSW bonus)
      await _usersProfileRef.child(offer.sellerUsername).runTransaction((Object? mutableData) {
        if (mutableData == null) return Transaction.abort();
        Map<String, dynamic> profile = Map<String, dynamic>.from(mutableData as Map);
        double currentPoSW = (profile['poSWScore'] as num?)?.toDouble() ?? 0.0;
        profile['poSWScore'] = currentPoSW + (0.05 * offer.amountKWh);
        return Transaction.success(profile);
      });

      await offerRef.remove();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully bought ${offer.amountKWh.toStringAsFixed(1)} kWh!'), backgroundColor: Colors.green)
      );
      if(mounted && _currentUserProfile!.username == _loggedInUsername) { // Optimistic update for buyer
          setState(() {
              _currentUserProfile!.energyBalanceKWh += offer.amountKWh;
              _currentUserProfile!.poSWScore += 0.02;
          });
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete purchase: $e'), backgroundColor: Colors.red)
      );
    } finally {
      if(mounted) setState(() { _isLoadingOffers = false; });
    }
  }


  @override
  Widget build(BuildContext context) {
    bool canPlaceOffer = _currentUserProfile != null && _loggedInUsername != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Energy Market (Custom Auth)'),
      ),
      body: _isLoadingOffers
          ? Center(child: CircularProgressIndicator())
          : _sellOffers.isEmpty
              ? Center(child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('No energy offers available right now. Check back later or place your own!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
              ))
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0),
                  itemCount: _sellOffers.length,
                  itemBuilder: (ctx, index) {
                    final offer = _sellOffers[index];
                    bool isMyOffer = offer.sellerUsername == _loggedInUsername;
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(Icons.offline_bolt_outlined, color: Colors.white),
                          backgroundColor: isMyOffer ? Colors.blueGrey[300] : Theme.of(context).colorScheme.secondary,
                        ),
                        title: Text('${offer.amountKWh.toStringAsFixed(1)} kWh at \$${offer.pricePerKWh.toStringAsFixed(2)}/kWh', style: TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          'Seller: ${isMyOffer ? "You" : offer.sellerUsername} (PoSW: ${offer.poSWSellerScore.toStringAsFixed(1)})\nPosted: ${offer.timestamp.toLocal().toString().substring(0,16)}',
                        ),
                        isThreeLine: true,
                        trailing: isMyOffer
                            ? IconButton(icon: Icon(Icons.delete_outline, color: Colors.redAccent), tooltip: "Remove your offer", onPressed: () async {
                                try {
                                   await _marketRef.child(offer.offerId).remove();
                                   await _usersProfileRef.child(offer.sellerUsername).runTransaction((Object? mutableData){ // Use sellerUsername
                                      if (mutableData == null) return Transaction.abort();
                                      Map<String, dynamic> profile = Map<String, dynamic>.from(mutableData as Map);
                                      double currentEnergy = (profile['energyBalanceKWh'] as num?)?.toDouble() ?? 0.0;
                                      profile['energyBalanceKWh'] = currentEnergy + offer.amountKWh;
                                      return Transaction.success(profile);
                                   });
                                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Your offer removed, energy restored.'), backgroundColor: Colors.orange));
                                    if(mounted && _currentUserProfile != null && _currentUserProfile!.username == offer.sellerUsername) {
                                        setState(() { // Optimistic update for seller (if current user)
                                            _currentUserProfile!.energyBalanceKWh += offer.amountKWh;
                                        });
                                    }
                                } catch (e) {
                                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove offer: $e'), backgroundColor: Colors.red));
                                }
                            })
                            : ElevatedButton(
                                child: Text('Buy'),
                                onPressed: (_loggedInUsername == null || _loggedInUsername == offer.sellerUsername) ? null : () => _buyOffer(offer), // Disable if not logged in or own offer
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                      ),
                    );
                  },
                ),
      floatingActionButton: canPlaceOffer ? FloatingActionButton.extended(
        onPressed: _showPlaceOfferDialog,
        label: Text('Sell Energy'),
        icon: Icon(Icons.add_shopping_cart_outlined),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
      ) : null,
    );
  }
}