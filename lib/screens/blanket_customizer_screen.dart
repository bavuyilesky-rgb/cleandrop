import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/laundry_models.dart';

class BlanketCustomizerScreen extends StatefulWidget {
  final ServiceCatalogItem service;

  const BlanketCustomizerScreen({super.key, required this.service});

  @override
  State<BlanketCustomizerScreen> createState() =>
      _BlanketCustomizerScreenState();
}

class _BlanketCustomizerScreenState extends State<BlanketCustomizerScreen> {
  String _selectedFabric = 'Plush Microfibre';
  bool _stainsPresent = true;
  String _selectedStainType = 'Mud / Dirt';
  bool _delicateTrim = false;
  bool _preExistingTears = true;
  final int _quantity = 1;
  String? _capturedPhotoPath;
  final TextEditingController _notesCtrl = TextEditingController();

  double get _calculatedPrice {
    final base = widget.service.price * _quantity;
    final stainAddon = _stainsPresent ? (15.0 * _quantity) : 0.0;
    return base + stainAddon;
  }

  Future<void> _takeInspectionPhoto(ImageSource src) async {
    try {
      final picker = ImagePicker();
      final XFile? file =
      await picker.pickImage(source: src, imageQuality: 75);
      if (file != null && mounted) {
        setState(() => _capturedPhotoPath = file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera notice: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fabrics = [
      {'title': 'Plush Microfibre', 'sub': 'Velvet / Sherpa soft'},
      {'title': 'Synthetic / Polyester', 'sub': 'Standard fleece & weave'},
      {'title': '100% Wool', 'sub': 'Cold hydro wash'},
      {'title': 'Down / Feather', 'sub': 'Special low tumble'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Blanket Customisation & Intake',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.darkNavy,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.bed_rounded,
                          color: AppColors.mintAccent, size: 36),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.service.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.tagBlue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'R ${widget.service.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkNavy,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Base Service',
                                  style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Blanket Material Composition',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fabrics.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.1,
              ),
              itemBuilder: (context, i) {
                final f = fabrics[i];
                final selected = _selectedFabric == f['title'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedFabric = f['title']!),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.mintAccent.withOpacity(0.15)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppColors.deepEmerald
                            : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                f['title']!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Text(
                                f['sub']!,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: selected ? AppColors.deepEmerald : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Condition Assessment Checklist',
                      style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.deepEmerald,
                      value: _stainsPresent,
                      onChanged: (v) =>
                          setState(() => _stainsPresent = v ?? false),
                      title: const Text('Stains present (+R15 Pre-treatment)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    if (_stainsPresent)
                      Wrap(
                        spacing: 8,
                        children: [
                          'Food / Grease',
                          'Mud / Dirt',
                          'Beverage / Wine'
                        ].map((st) {
                          final active = _selectedStainType == st;
                          return ChoiceChip(
                            label: Text(st),
                            selected: active,
                            selectedColor: AppColors.deepEmerald,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              color: active ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) =>
                                setState(() => _selectedStainType = st),
                          );
                        }).toList(),
                      ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.deepEmerald,
                      value: _delicateTrim,
                      onChanged: (v) =>
                          setState(() => _delicateTrim = v ?? false),
                      title: const Text('Delicate trim / Satin edge binding',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.deepEmerald,
                      value: _preExistingTears,
                      onChanged: (v) =>
                          setState(() => _preExistingTears = v ?? false),
                      title: const Text('Pre-existing tears / loose stitching',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inspection Camera Intake',
                      style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    if (_capturedPhotoPath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(_capturedPhotoPath!),
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _takeInspectionPhoto(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Take photo of stains / tags'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () =>
                              _takeInspectionPhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Special Care Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.pop(
                context,
                BasketLineItem(
                  service: widget.service,
                  quantity: _quantity,
                  fabricComposition: _selectedFabric,
                  hasStains: _stainsPresent,
                  stainCategory: _selectedStainType,
                  hasDelicateTrim: _delicateTrim,
                  hasPreExistingTears: _preExistingTears,
                  careNotes: _notesCtrl.text.trim(),
                  localPhotoPath: _capturedPhotoPath,
                ),
              );
            },
            icon: const Icon(Icons.shopping_bag_outlined),
            label: Text(
              'Add to Basket • R ${_calculatedPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}