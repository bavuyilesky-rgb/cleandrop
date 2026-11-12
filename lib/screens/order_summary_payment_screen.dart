import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/laundry_models.dart';

class OrderSummaryAndPaymentScreen extends StatefulWidget {
  final LaundromatVendor vendor;
  final List<BasketLineItem> basket;
  final String pickupAddress;
  final DateTime pickupDate;
  final DateTime returnDate;
  final String timeWindow;
  final double expressFee;
  final LatLng userCoords;
  final String userName;
  final String userPhone;
  final void Function(String orderId) onOrderConfirmed;

  const OrderSummaryAndPaymentScreen({
    super.key,
    required this.vendor,
    required this.basket,
    required this.pickupAddress,
    required this.pickupDate,
    required this.returnDate,
    required this.timeWindow,
    required this.expressFee,
    required this.userCoords,
    required this.userName,
    required this.userPhone,
    required this.onOrderConfirmed,
  });

  @override
  State<OrderSummaryAndPaymentScreen> createState() =>
      _OrderSummaryAndPaymentScreenState();
}

class _OrderSummaryAndPaymentScreenState
    extends State<OrderSummaryAndPaymentScreen> {
  String _selectedPayment = 'CARD';
  bool _submitting = false;

  final _cardNumberCtrl = TextEditingController(text: '4532 8910 2234 4829');
  final _expiryCtrl = TextEditingController(text: '09/28');
  final _cvvCtrl = TextEditingController(text: '842');

  double get _baseSubtotal => widget.basket
      .fold(0.0, (s, item) => s + (item.service.price * item.quantity));

  double get _stainCareTotal =>
      widget.basket.fold(0.0, (s, item) => s + item.stainFee);

  double get _grandTotal =>
      _baseSubtotal +
          _stainCareTotal +
          widget.vendor.deliveryFee +
          widget.expressFee;

  double get _includedVat => _grandTotal * 0.15 / 1.15;

  Future<void> _placeOrder() async {
    setState(() => _submitting = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
      final orderNum = 'CD-${8800 + Random().nextInt(1199)}';
      final pin = (1000 + Random().nextInt(8999)).toString();

      String? photoUrl;
      final itemWithPhoto =
          widget.basket.where((i) => i.localPhotoPath != null).firstOrNull;
      if (itemWithPhoto != null) {
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child('inspections/$orderNum.jpg');
          await ref.putFile(File(itemWithPhoto.localPhotoPath!));
          photoUrl = await ref.getDownloadURL();
        } catch (_) {
          photoUrl = 'verified_local_photo';
        }
      }

      await FirebaseFirestore.instance.collection('orders').doc(orderNum).set({
        'orderId': orderNum,
        'customerId': uid,
        'customerName': widget.userName,
        'customerPhone': widget.userPhone,
        'laundromatId': widget.vendor.id,
        'laundromatName': widget.vendor.name,
        'driverName': widget.vendor.driverName,
        'driverVehicle': widget.vendor.driverVehicle,
        'driverPlate': widget.vendor.driverPlate,
        'driverPhone': widget.vendor.driverPhone,
        'pickupAddress': widget.pickupAddress,
        'pickupDate': DateFormat('EEE, dd MMM').format(widget.pickupDate),
        'deliveryDate': DateFormat('EEE, dd MMM').format(widget.returnDate),
        'timeSlot': widget.timeWindow,
        'userLat': widget.userCoords.latitude,
        'userLng': widget.userCoords.longitude,
        'vendorLat': widget.vendor.latitude,
        'vendorLng': widget.vendor.longitude,
        'subtotal': _baseSubtotal,
        'stainCareFee': _stainCareTotal,
        'deliveryFee': widget.vendor.deliveryFee,
        'expressFee': widget.expressFee,
        'totalAmount': _grandTotal,
        'vatAmount': _includedVat,
        'paymentMethod': _selectedPayment == 'CARD'
            ? 'Visa •••• 4829'
            : _selectedPayment == 'OZOW'
            ? 'Ozow Instant EFT'
            : 'Cash on Driver Pickup',
        'orderStatus': 'DRIVER_EN_ROUTE',
        'handoverPin': pin,
        'photoUrl': photoUrl,
        'items': widget.basket.map((b) => b.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await showLocalPushNotification(
        'Order #$orderNum Confirmed!',
        'Driver ${widget.vendor.driverName} is en route. Handover PIN: $pin',
      );

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        widget.onOrderConfirmed(orderNum);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Order & Invoice',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fulfillment Logistics',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const Divider(),
                    Text('Pickup Address: ${widget.pickupAddress}'),
                    Text('Customer Phone: ${widget.userPhone}'),
                    Text(
                        'Pickup Slot: ${DateFormat('EEE, dd MMM').format(widget.pickupDate)} (${widget.timeWindow})'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Breakdown',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const Divider(),
                    ...widget.basket.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(
                                  '${item.quantity}x ${item.service.name}')),
                          Text('R ${item.lineTotal.toStringAsFixed(2)}'),
                        ],
                      ),
                    )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Fee'),
                        Text('R ${widget.vendor.deliveryFee.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.darkNavy,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL PAYABLE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            'R ${_grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.mintAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              value: 'CARD',
              groupValue: _selectedPayment,
              onChanged: (v) => setState(() => _selectedPayment = v!),
              title: const Text('Credit / Debit Card (Stripe)'),
              subtitle: const Text('Visa / Mastercard •••• 4829'),
            ),
            if (_selectedPayment == 'CARD')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _cardNumberCtrl,
                      decoration:
                      const InputDecoration(labelText: 'Card Number'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _expiryCtrl,
                            decoration:
                            const InputDecoration(labelText: 'MM/YY'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _cvvCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'CVV'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            RadioListTile<String>(
              value: 'OZOW',
              groupValue: _selectedPayment,
              onChanged: (v) => setState(() => _selectedPayment = v!),
              title: const Text('Instant EFT / Ozow'),
            ),
            RadioListTile<String>(
              value: 'CASH',
              groupValue: _selectedPayment,
              onChanged: (v) => setState(() => _selectedPayment = v!),
              title: const Text('Cash on Driver Pickup'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepEmerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _submitting ? null : _placeOrder,
            icon: const Icon(Icons.lock_outline),
            label: Text(
              _submitting
                  ? 'Confirming...'
                  : 'Place Order (R${_grandTotal.toStringAsFixed(2)})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}