import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../secrets.dart'; // Ensure this path is correct and geminiApiKey is defined

// Re-using WasteAnalysisDetails class
class WasteAnalysisDetails {
  final String? primaryCategory;
  final String? specificItems;
  final String? geminiEstimatedQuantity; 
  final String? conditionNotes;
  final List<String> suggestedUses;
  final Map<String, String> composition;
  final String? suggestedPrice;
  final String? co2SavedEstimate;
  final String rawResponse;

  WasteAnalysisDetails({
    this.primaryCategory,
    this.specificItems,
    this.geminiEstimatedQuantity,
    this.conditionNotes,
    this.suggestedUses = const [],
    this.composition = const {},
    this.suggestedPrice,
    this.co2SavedEstimate,
    required this.rawResponse,
  });

  static String? _extractValue(String text, String label) {
    final regex = RegExp(
      r"(?:\d+\s*\.\s*)?" + RegExp.escape(label) + r":\s*(.*?)(?=\n\s*(?:\d+\s*\.\s*)?\w+:\s*|\n*$)",
      caseSensitive: false, multiLine: true, dotAll: true,
    );
    final match = regex.firstMatch(text);
    return match?.group(1)?.trim();
  }

  factory WasteAnalysisDetails.fromRawText(String rawText) {
    String? category = _extractValue(rawText, "Primary Waste Category");
    String? items = _extractValue(rawText, "Specific Items");
    String? geminiQuantity = _extractValue(rawText, "Estimated Quantity (Visual)");
    String? notes = _extractValue(rawText, "Condition/Notes") ?? _extractValue(rawText, "Brief Description");
    String? price = _extractValue(rawText, "Suggested Market Price") ?? _extractValue(rawText, "Estimated Market Value");
    String? co2 = _extractValue(rawText, "Estimated CO2 Saved Potential") ?? _extractValue(rawText, "Potential CO2 Reduction");
    
    List<String> uses = [];
    String? usesText = _extractValue(rawText, "Suggested Uses");
    if (usesText != null && usesText.isNotEmpty) {
      uses = usesText.split(RegExp(r',|;')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    Map<String, String> comp = {};
    String? compText = _extractValue(rawText, "Approximate Composition");
    if (compText != null && compText.isNotEmpty) {
      List<String> compPairs = compText.split(RegExp(r',|;')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      for (String pair in compPairs) {
        List<String> kv = pair.split(':').map((e) => e.trim()).toList();
        if (kv.length == 2 && kv[0].isNotEmpty && kv[1].isNotEmpty) {
          comp[kv[0]] = kv[1];
        }
      }
    }
    
    if (category == null && rawText.isNotEmpty && !rawText.contains("\n") && rawText.length < 50) {
        category = rawText;
    }

    return WasteAnalysisDetails(
      primaryCategory: category,
      specificItems: items,
      geminiEstimatedQuantity: geminiQuantity,
      conditionNotes: notes,
      suggestedUses: uses,
      composition: comp,
      suggestedPrice: price,
      co2SavedEstimate: co2,
      rawResponse: rawText,
    );
  }
}

class NewWasteListingScreen extends StatefulWidget {
  static const String routeName = '/new-waste-listing';
  const NewWasteListingScreen({super.key});

  @override
  State<NewWasteListingScreen> createState() => _NewWasteListingScreenState();
}

class _NewWasteListingScreenState extends State<NewWasteListingScreen> {
  final _formKey = GlobalKey<FormState>();
  XFile? _mediaFile;
  final ImagePicker _picker = ImagePicker();
  
  WasteAnalysisDetails? _geminiAnalysisDetails;
  bool _isAnalyzingWithGemini = false;
  String? _operationErrorMessage; 
  String? _uploadedMediaUrl; 

  bool _isUploadingMedia = false;
  bool _isSubmittingListing = false;
  double _mediaUploadProgress = 0.0;

  String? _selectedCropType;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final TextEditingController _wasteTypeDisplayController = TextEditingController();
  final TextEditingController _suggestedUseDisplayController = TextEditingController();
  final TextEditingController _suggestedPriceDisplayController = TextEditingController();
  final TextEditingController _co2SavedDisplayController = TextEditingController();

  final List<String> _cropTypes = ['Select Crop Type', 'Rice Straw', 'Wheat Straw', 'Corn Stover', 'Sugarcane Bagasse', 'Cotton Stalks', 'Banana Pseudostem', 'Jute Sticks', 'Other Agricultural Residue', 'Mixed Organic'];
  final List<String> _promptWasteCategories = [
    'paper', 'cardboard', 'plastic', 'PET bottles', 'HDPE containers', 
    'metal', 'aluminum cans', 'steel cans', 'glass', 'organic waste', 
    'food scraps', 'yard trimmings', 'e-waste', 'batteries', 'electronics',
    'textiles', 'clothing', 'hazardous waste', 'chemicals', 'paints', 
    'construction debris', 'wood', 'concrete', 'mixed/general trash',
    'sugarcane bagasse', 'rice husk', 'wheat straw', 'corn stover', 'cotton stalks', 'jute sticks',
    'banana pseudostem'
  ];

  @override
  void initState() {
    super.initState();
    _selectedCropType = _cropTypes[0];
    // Add listeners to text controllers to rebuild UI for button state changes
    _quantityController.addListener(_onInputChanged);
    _locationController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (mounted) {
      setState(() {
        // This empty setState call is enough to trigger a rebuild
        // and re-evaluate the `canTriggerAnalysisButton` in the build method.
      });
    }
  }

  void _clearAnalysisFieldsAndError() {
      _wasteTypeDisplayController.clear();
      _suggestedUseDisplayController.clear();
      _suggestedPriceDisplayController.clear();
      _co2SavedDisplayController.clear();
      _geminiAnalysisDetails = null;
      if(mounted) setState(() => _operationErrorMessage = null); 
  }

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
     try {
      XFile? pickedFile;
      if (isVideo) {
        pickedFile = await _picker.pickVideo(source: source, maxDuration: const Duration(seconds: 60));
      } else {
        pickedFile = await _picker.pickImage(source: source, imageQuality: 70, maxWidth: 1280);
      }

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _mediaFile = pickedFile;
          _uploadedMediaUrl = null; 
          _clearAnalysisFieldsAndError();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking media: ${e.toString()}")),
        );
      }
    }
  }

  Future<String?> _uploadMediaToStorageInternal(XFile mediaFile) async {
    if (!mounted) return null;
    setState(() {
      _isUploadingMedia = true; 
      _mediaUploadProgress = 0.0;
      _operationErrorMessage = null; 
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("User not authenticated. Please login.");

      String fileExtension = mediaFile.path.split('.').last.toLowerCase();
      String mimeType = 'application/octet-stream'; 
      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension)) {
        mimeType = 'image/$fileExtension';
      } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(fileExtension)) {
        mimeType = 'video/$fileExtension';
      }
      
      final String fileName = 'waste_listings_media/${currentUser.uid}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      
      UploadTask uploadTask = storageRef.putFile(File(mediaFile.path), SettableMetadata(contentType: mimeType));

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) setState(() => _mediaUploadProgress = snapshot.bytesTransferred.toDouble() / snapshot.totalBytes.toDouble());
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      if (mounted) {
        setState(() {
         _uploadedMediaUrl = downloadUrl;
        });
      }
      return downloadUrl;
    } catch (e) {
      print("Firebase Storage Upload Error: $e"); 
      if (mounted) {
        String errorMessage = "Media upload failed. CRITICAL: Check Firebase Storage rules. Error: ${e.toString().split(']').last.trim()}";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage, style: const TextStyle(fontSize: 12)), duration: const Duration(seconds: 6), backgroundColor: Colors.red,));
        setState(() {
          _operationErrorMessage = errorMessage;
        });
      }
      return null;
    } finally {
        if(mounted) {
            setState(() {
                _isUploadingMedia = false; 
            });
        }
    }
  }

  Future<void> _triggerGeminiAnalysis() async {
    // This initial check is for user feedback before starting any async operations
    if (_mediaFile == null || _selectedCropType == _cropTypes[0] || _quantityController.text.trim().isEmpty || _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please ensure Media, Crop Type, Quantity, and Location are filled.")));
      _formKey.currentState?.validate(); // Show validation hints on fields
      return;
    }

    setState(() {
      _isAnalyzingWithGemini = true;
      _operationErrorMessage = null; 
      _clearAnalysisFieldsAndError();
    });

    String? currentMediaUrl = _uploadedMediaUrl;

    try {
      if (currentMediaUrl == null) { // If media wasn't uploaded from a previous attempt or separate action
        currentMediaUrl = await _uploadMediaToStorageInternal(_mediaFile!);
        if (currentMediaUrl == null) {
          // Error message is already set by _uploadMediaToStorageInternal
          // The finally block below will reset _isAnalyzingWithGemini
          return; 
        }
      }
      
      bool isVideoFile = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(_mediaFile!.path.split('.').last.toLowerCase());
      if (isVideoFile) {
          throw Exception("AI description from image is supported. Video analysis is not available with this feature yet.");
      }

      final imageBytes = await File(_mediaFile!.path).readAsBytes();
      final String base64ImageData = base64Encode(imageBytes);
      
      String prompt = "You are an agricultural waste valorization expert. Based on the provided image, crop type '${_selectedCropType}', quantity '${_quantityController.text}', and location context '${_locationController.text}', provide a detailed analysis. "
                      "Structure your response with the following numbered points. Be concise and factual:\n"
                      "1. Primary Waste Category: (Confirm or refine based on image and crop type. E.g., '${_selectedCropType}' or a more specific type if visible in image.)\n"
                      "2. Specific Items: (Describe items visible in image, e.g., 'chopped stalks', 'dried leaves')\n"
                      "3. Estimated Quantity (Visual): (Your visual estimate from image, e.g., 'small pile', 'several bundles')\n"
                      "4. Condition/Notes: (Observed condition, e.g., 'dry', 'recently harvested', 'suitable for immediate processing')\n"
                      "5. Suggested Uses: (List 2-4 potential uses, comma-separated, e.g., 'Biofuel, Composting, Animal Feed')\n"
                      "6. Approximate Composition: (Typical composition if known for '${_selectedCropType}', e.g., 'Cellulose: 30-40%, Lignin: 15-20%'. If image shows something different, note it.)\n"
                      "7. Suggested Market Price: (Very rough estimate per unit (e.g., per ton/kg) for '${_selectedCropType}' in '${_locationController.text}' region, e.g., '₹X-Y per ton'. State if value is low or for specific uses.)\n"
                      "8. Estimated CO2 Saved Potential: (Qualitative or very rough quantitative estimate if valorized, e.g., 'Significant reduction if composted instead of burned', 'Approx Z kg CO2e offset per ton if used for biofuel'.)\n";
      
      final String apiKeyFromSecrets = geminiApiKey;
      final String apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKeyFromSecrets";

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts": [{"text": prompt}, {"inlineData": {"mimeType": _mediaFile!.path.endsWith('png') ? "image/png" : "image/jpeg", "data": base64ImageData}}]}],
          "generationConfig": {"temperature": 0.3, "topK": 5, "topP": 0.95, "maxOutputTokens": 2048}
        }),
      ).timeout(const Duration(seconds: 120));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> resultData = jsonDecode(response.body);
        if (resultData.containsKey('candidates') && (resultData['candidates'] as List).isNotEmpty) {
          String rawText = resultData['candidates'][0]['content']?['parts']?[0]?['text']?.toString()?.trim() ?? "";
          print("Gemini Raw Text for Listing Description:\n$rawText");
          setState(() {
            _geminiAnalysisDetails = WasteAnalysisDetails.fromRawText(rawText);
            _wasteTypeDisplayController.text = _geminiAnalysisDetails?.primaryCategory ?? '';
            _suggestedUseDisplayController.text = _geminiAnalysisDetails?.suggestedUses.join(', ') ?? '';
            _suggestedPriceDisplayController.text = _geminiAnalysisDetails?.suggestedPrice ?? '';
            _co2SavedDisplayController.text = _geminiAnalysisDetails?.co2SavedEstimate ?? '';
          });
        } else {
          _operationErrorMessage = "Could not parse Gemini's response.";
        }
      } else {
        _operationErrorMessage = "Gemini API error (${response.statusCode}): ${response.body.length > 200 ? response.body.substring(0,200) : response.body}";
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_operationErrorMessage == null) { 
            _operationErrorMessage = "Analysis Error: ${e.toString()}";
          }
        });
      }
      print("Gemini Analysis Exception: $e");
    } finally {
      if (mounted) setState(() => _isAnalyzingWithGemini = false);
    }
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required (*) fields.')));
      return;
    }
     if (_wasteTypeDisplayController.text.trim().isEmpty) { 
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Waste Type (from AI description) is required. Please click "Get AI Description" or fill manually if allowed.')));
       return;
    }
    if (_mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload an image or video.')));
      return;
    }
    
    if (_uploadedMediaUrl == null) {
        String? tempUrl = await _uploadMediaToStorageInternal(_mediaFile!);
        if (tempUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Media upload failed. Cannot submit listing.')));
          return; 
        }
    }

    setState(() => _isSubmittingListing = true);
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("User not authenticated.");
      bool isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(_mediaFile!.path.split('.').last.toLowerCase());
      Map<String, dynamic> listingData = { 
        'userId': currentUser.uid, 'userEmail': currentUser.email, 'mediaUrl': _uploadedMediaUrl, 
        'mediaType': isVideo ? 'video' : 'image', 'cropType': _selectedCropType == _cropTypes[0] ? null : _selectedCropType,
        'quantity': _quantityController.text.trim(), 'location': _locationController.text.trim(),
        'wasteType': _wasteTypeDisplayController.text.trim(), 'suggestedUse': _suggestedUseDisplayController.text.trim(),
        'suggestedPrice': _suggestedPriceDisplayController.text.trim(), 'co2SavedEstimate': _co2SavedDisplayController.text.trim(),
        'geminiRawResponse': _geminiAnalysisDetails?.rawResponse, 'status': 'active',
        'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('wasteListings').add(listingData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Waste listing submitted successfully!'), backgroundColor: Colors.green));
        _formKey.currentState?.reset();
        setState(() { 
          _mediaFile = null; _uploadedMediaUrl = null; _selectedCropType = _cropTypes[0];
          _quantityController.clear(); _locationController.clear();
          _clearAnalysisFieldsAndError();
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Submission Error: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _isSubmittingListing = false);
    }
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onInputChanged);
    _locationController.removeListener(_onInputChanged);
    _quantityController.dispose();
    _locationController.dispose();
    _wasteTypeDisplayController.dispose();
    _suggestedUseDisplayController.dispose();
    _suggestedPriceDisplayController.dispose();
    _co2SavedDisplayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    bool isDarkMode = theme.brightness == Brightness.dark;
    Color cardColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    Color subtleTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    
    // This is the crucial logic for enabling the "Get AI Description" button
    bool canTriggerAnalysisButton = _mediaFile != null &&
                             _selectedCropType != _cropTypes[0] &&
                             _quantityController.text.trim().isNotEmpty &&
                             _locationController.text.trim().isNotEmpty &&
                             !_isAnalyzingWithGemini && !_isSubmittingListing && !_isUploadingMedia;

    bool canSubmitListingButton = _mediaFile != null && 
                            _uploadedMediaUrl != null && 
                            _selectedCropType != _cropTypes[0] &&
                            _quantityController.text.trim().isNotEmpty &&
                            _locationController.text.trim().isNotEmpty &&
                            _wasteTypeDisplayController.text.trim().isNotEmpty && 
                            !_isAnalyzingWithGemini && !_isSubmittingListing && !_isUploadingMedia;


    return Scaffold(
      appBar: AppBar(
        title: const Text('List Your Agricultural Waste'),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.disabled, 
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isWideScreen = constraints.maxWidth > 750; 
              if (isWideScreen) {
                return Row( 
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildInputFormLeft(theme, subtleTextColor)),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: _buildAIDescriptionAndSubmitColumn(theme, cardColor, subtleTextColor, canTriggerAnalysisButton, canSubmitListingButton)),
                  ],
                );
              } else { 
                return Column( 
                  children: [
                    _buildInputFormLeft(theme, subtleTextColor),
                    const SizedBox(height: 20),
                    _buildAIDescriptionAndSubmitColumn(theme, cardColor, subtleTextColor, canTriggerAnalysisButton, canSubmitListingButton),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputFormLeft(ThemeData theme, Color subtleTextColor) {
    bool isVideoFile = _mediaFile?.path.split('.').last.toLowerCase() == 'mp4' ||
                       _mediaFile?.path.split('.').last.toLowerCase() == 'mov'; 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("1. Provide Waste Details", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        Text("Upload Waste Image/Video *", style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: (_isUploadingMedia || _isSubmittingListing || _isAnalyzingWithGemini) ? null : () => _pickMedia(ImageSource.gallery),
          child: Container( 
             height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor), 
            ),
            child: _mediaFile == null
                ? Column( 
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 50, color: theme.colorScheme.primary),
                      const SizedBox(height: 8),
                      Text("Tap to upload Image/Video", style: TextStyle(color: subtleTextColor)),
                      Text("PNG, JPG, MP4 up to 10MB", style: theme.textTheme.bodySmall?.copyWith(color: subtleTextColor)),
                    ],
                  )
                : Stack( 
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: isVideoFile 
                               ? Container(color: Colors.black, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.videocam_outlined, color: Colors.white, size: 50), Text(_mediaFile!.name, style: const TextStyle(color: Colors.white, fontSize: 10)) ])))
                               : Image.file(File(_mediaFile!.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                      ),
                       Positioned(top: 4, right: 4, child: Material(color: Colors.black54, borderRadius: BorderRadius.circular(20), child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 18), onPressed: (){ setState(() { _mediaFile = null; _uploadedMediaUrl = null; _clearAnalysisFieldsAndError(); });}, splashRadius: 18, padding: EdgeInsets.zero, constraints: const BoxConstraints(),))),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
         Row( 
           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
           children: [
             TextButton.icon(icon: const Icon(Icons.photo_library_outlined, size: 18), label: const Text("Image"), onPressed: (_isUploadingMedia || _isSubmittingListing || _isAnalyzingWithGemini) ? null : () => _pickMedia(ImageSource.gallery, isVideo: false)),
             TextButton.icon(icon: const Icon(Icons.videocam_outlined, size: 18), label: const Text("Video"), onPressed: (_isUploadingMedia || _isSubmittingListing || _isAnalyzingWithGemini) ? null : () => _pickMedia(ImageSource.gallery, isVideo: true)),
             TextButton.icon(icon: const Icon(Icons.camera_alt_outlined, size: 18), label: const Text("Camera"), onPressed: (_isUploadingMedia || _isSubmittingListing || _isAnalyzingWithGemini) ? null : () async {
                await showDialog(context: context, builder: (ctx) => AlertDialog(
                  title: const Text("Capture Media"), content: const Text("Choose to capture an image or video."),
                  actions: [
                    TextButton(onPressed: (){ Navigator.pop(ctx); _pickMedia(ImageSource.camera, isVideo: false);}, child: const Text("Image")),
                    TextButton(onPressed: (){ Navigator.pop(ctx); _pickMedia(ImageSource.camera, isVideo: true);}, child: const Text("Video")),
                  ],));}),
           ],
         ),
        if (_isUploadingMedia) ...[
          const SizedBox(height: 10),
          LinearProgressIndicator(value: _mediaUploadProgress, backgroundColor: Colors.grey[300]),
          Text("Uploading: ${(_mediaUploadProgress * 100).toStringAsFixed(0)}%"),
        ],
        const SizedBox(height: 20),

        _buildDropdownFormField(_cropTypes, _selectedCropType, "Select Crop Type *", (newValue) {
          setState(() => _selectedCropType = newValue);
        }),
        const SizedBox(height: 16),
        TextFormField(
          controller: _quantityController,
          decoration: InputDecoration(labelText: 'Quantity (e.g., tons, kg, items) *', border: const OutlineInputBorder(), hintText: "e.g., 2.5 tons or 100 items"),
          keyboardType: TextInputType.text,
          validator: (value) => (value == null || value.isEmpty) ? 'Please enter quantity' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(labelText: 'Location (e.g., Village, District) *', border: const OutlineInputBorder()),
          validator: (value) => (value == null || value.isEmpty) ? 'Please enter location' : null,
        ),
      ],
    );
  }

  Widget _buildAIDescriptionAndSubmitColumn(ThemeData theme, Color cardColor, Color subtleTextColor, bool canTriggerAnalysisButton, bool canSubmitListingButton) {
    return Card(
      elevation: 1,
      color: cardColor.withOpacity(0.8), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: theme.dividerColor)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("2. AI Powered Description", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Fill details in Part 1, then click below to get AI suggestions. Fields below will be auto-filled.", style: TextStyle(color: subtleTextColor, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: _isAnalyzingWithGemini 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(_isAnalyzingWithGemini ? "Analyzing..." : "Get AI Description"),
              onPressed: canTriggerAnalysisButton ? _triggerGeminiAnalysis : null,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45), backgroundColor: theme.colorScheme.secondary, foregroundColor: theme.colorScheme.onSecondary),
            ),
            if (_operationErrorMessage != null) Padding( 
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_operationErrorMessage!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
            ),
            const Divider(height: 24),

            _buildDisplayField(theme, "Waste Type / Primary Category *", _wasteTypeDisplayController, Icons.eco_outlined, "Auto-filled by AI", isRequired: true),
            _buildDisplayField(theme, "Suggested Uses (comma-separated)", _suggestedUseDisplayController, Icons.recycling_outlined, "Auto-filled by AI", maxLines: 2),
            _buildDisplayField(theme, "Suggested Price (e.g., per ton/kg)", _suggestedPriceDisplayController, Icons.price_change_outlined, "Auto-filled by AI"),
            _buildDisplayField(theme, "Estimated CO₂ Saved (if known)", _co2SavedDisplayController, Icons.air_outlined, "Auto-filled by AI", maxLines: 2),
            
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: _isSubmittingListing 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isSubmittingListing ? "Submitting..." : 'Submit Waste Listing'),
              onPressed: canSubmitListingButton ? _submitListing : null, 
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
            if (!canSubmitListingButton && _mediaFile != null && !_isSubmittingListing && !_isAnalyzingWithGemini)
              Padding(
                padding: const EdgeInsets.only(top:8.0),
                child: Text(
                  _uploadedMediaUrl == null 
                  ? "Hint: Media not uploaded. Click 'Get AI Description' first (this also uploads media)."
                  : "Hint: Ensure 'Waste Type' (from AI) is filled before submitting.", 
                  style: TextStyle(fontSize: 11, color: theme.hintColor)
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFormField(List<String> items, String? currentValue, String labelText, ValueChanged<String?> onChanged) {
     return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: labelText, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
      value: currentValue,
      isExpanded: true,
      items: items.map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value, overflow: TextOverflow.ellipsis));
      }).toList(),
      onChanged: (value) {
        setState(() { // Ensure dropdown changes trigger a rebuild for button state
          onChanged(value);
        });
      },
      validator: (value) => value == items[0] ? 'Please select an option' : null,
    );
  }

  Widget _buildDisplayField(ThemeData theme, String label, TextEditingController controller, IconData icon, String hintText, {int maxLines = 1, bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField( 
        controller: controller,
        readOnly: true, 
        decoration: InputDecoration(
          labelText: label + (isRequired ? " *" : ""),
          hintText: hintText,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon, size: 20, color: theme.colorScheme.primary),
          filled: true,
          fillColor: theme.colorScheme.onSurface.withOpacity(0.04),
        ),
        maxLines: maxLines,
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
        validator: isRequired ? (value) => (value == null || value.isEmpty) ? 'This AI-suggested field is required for submission' : null : null,
      ),
    );
  }
}

