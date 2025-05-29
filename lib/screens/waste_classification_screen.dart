import 'dart:io';
import 'dart:convert'; // For jsonEncode, jsonDecode, base64Encode
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../secrets.dart'; // Assuming secrets.dart is in lib/

// Updated Data class to hold more structured information
class WasteAnalysisDetails {
  final String? primaryCategory;
  final String? specificItems;
  final String? estimatedQuantity;
  final String? conditionNotes;
  final List<String> suggestedUses;
  final Map<String, String> composition;
  final String rawResponse;

  WasteAnalysisDetails({
    this.primaryCategory,
    this.specificItems,
    this.estimatedQuantity,
    this.conditionNotes,
    this.suggestedUses = const [],
    this.composition = const {},
    required this.rawResponse,
  });

  // Helper function to extract content based on a label using regex
  static String? _extractValue(String text, String label) {
    // Regex to find the label (case insensitive) followed by a colon,
    // and capture everything until the next numbered label or end of string.
    // It handles potential numbering like "1.", "2.", etc., before the label.
    final regex = RegExp(
      r"(?:\d+\s*\.\s*)?" + RegExp.escape(label) + r":\s*(.*?)(?=\n\s*(?:\d+\s*\.\s*)?\w+:\s*|\n*$)",
      caseSensitive: false,
      multiLine: true,
      dotAll: true, // Allows . to match newlines within the value part
    );
    final match = regex.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)?.trim();
    }
    return null;
  }

  factory WasteAnalysisDetails.fromRawText(String rawText) {
    String? category = _extractValue(rawText, "Primary Waste Category");
    String? items = _extractValue(rawText, "Specific Items");
    String? quantity = _extractValue(rawText, "Estimated Quantity");
    String? notes = _extractValue(rawText, "Condition/Notes") ?? _extractValue(rawText, "Brief Description");
    
    List<String> uses = [];
    String? usesText = _extractValue(rawText, "Suggested Uses");
    if (usesText != null && usesText.isNotEmpty) {
      uses = usesText.split(RegExp(r',|;')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    Map<String, String> comp = {};
    String? compText = _extractValue(rawText, "Approximate Composition");
    if (compText != null && compText.isNotEmpty) {
      // Expecting format like "Cellulose: 40%, Lignin: 20%, Hemicellulose: 25%"
      // Or "Cellulose: 35-45%; Hemicellulose: 20-30%; Lignin: 15-25%"
      List<String> compPairs = compText.split(RegExp(r',|;')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      for (String pair in compPairs) {
        List<String> kv = pair.split(':').map((e) => e.trim()).toList();
        if (kv.length == 2 && kv[0].isNotEmpty && kv[1].isNotEmpty) {
          comp[kv[0]] = kv[1];
        }
      }
    }
    
    // If primary category is still null but the raw text seems to contain it (e.g. Gemini just gives the category)
    if (category == null && rawText.isNotEmpty && !rawText.contains("\n") && rawText.length < 50) {
        // Check if it matches any known categories (from _promptWasteCategories, which isn't accessible here directly)
        // This is a simple heuristic.
        category = rawText;
    }


    return WasteAnalysisDetails(
      primaryCategory: category,
      specificItems: items,
      estimatedQuantity: quantity,
      conditionNotes: notes,
      suggestedUses: uses,
      composition: comp,
      rawResponse: rawText, // Always store the raw response for debugging or fallback
    );
  }
}


class WasteClassificationScreen extends StatefulWidget {
  static const String routeName = '/classify-waste-gemini';

  const WasteClassificationScreen({super.key});

  @override
  State<WasteClassificationScreen> createState() =>
      _WasteClassificationScreenState();
}

class _WasteClassificationScreenState extends State<WasteClassificationScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  WasteAnalysisDetails? _analysisDetails;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _promptWasteCategories = [
    'paper', 'cardboard', 'plastic', 'PET bottles', 'HDPE containers', 
    'metal', 'aluminum cans', 'steel cans', 'glass', 'organic waste', 
    'food scraps', 'yard trimmings', 'e-waste', 'batteries', 'electronics',
    'textiles', 'clothing', 'hazardous waste', 'chemicals', 'paints', 
    'construction debris', 'wood', 'concrete', 'mixed/general trash',
    'sugarcane bagasse', 'rice husk', 'wheat straw', 'corn stover', 'cotton stalks', 'jute sticks',
    'banana pseudostem' // Added from your screenshot
  ];


  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1024, maxHeight: 1024);
      if (pickedFile != null) {
        if (mounted) {
          setState(() {
            _image = File(pickedFile.path);
            _analysisDetails = null;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error picking image: ${e.toString()}";
        });
      }
    }
  }

  Future<void> _classifyWasteWithGemini() async {
    if (_image == null) {
      if (mounted) {
        setState(() {
          _errorMessage = "Please select an image first.";
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _analysisDetails = null;
        _errorMessage = null;
      });
    }

    try {
      final imageBytes = await _image!.readAsBytes();
      final String base64ImageData = base64Encode(imageBytes);

      String prompt = "You are an expert in agricultural waste analysis. Analyze the contents of this image and provide details about the waste visible. "
                      "Structure your response with the following numbered points. Be concise and factual for each point. If a point is not clearly determinable, state 'Not clearly determinable'.\n"
                      "1. Primary Waste Category: (Identify the main type of waste. If it's agricultural, specify the crop if identifiable, e.g., 'sugarcane bagasse', 'cotton stalks', 'banana pseudostem'. Choose from or relate to: ${_promptWasteCategories.join(', ')}. If mixed, state 'mixed/general trash'.)\n"
                      "2. Specific Items: (List a few specific items or describe the form, e.g., 'chopped sugarcane stalks', 'dried cotton plants', 'shredded paper', 'sections of banana pseudostem')\n"
                      "3. Estimated Quantity: (Describe the visual quantity, e.g., 'a single stalk', 'a small handful', 'medium pile (approx 1-5 kg visually)', 'large heap (visually > 10 kg)')\n"
                      "4. Condition/Notes: (Briefly describe its condition, e.g., 'dry', 'moist', 'clean', 'mixed with soil', 'appears fresh', 'partially decomposed', 'recently cut')\n"
                      "5. Suggested Uses: (List 2-4 potential uses as comma-separated values, e.g., 'Biofuel, Composting, Animal Feed, Mulch', 'Composting, Animal Feed, Biogas production, Paper production'. Consider common uses for the identified waste type.)\n"
                      "6. Approximate Composition: (If identifiable as a common agricultural residue, provide a typical rough composition with component and percentage, e.g., 'Cellulose: 35-45%, Hemicellulose: 20-30%, Lignin: 15-25%'. If not applicable or unknown, state 'Not applicable' or 'General organic matter (High in moisture, cellulose, hemicellulose, and lignin)'.)\n";
      
      final String apiKeyFromSecrets = geminiApiKey; 
      
      final String apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKeyFromSecrets";

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
                {
                  "inlineData": {
                    "mimeType": "image/jpeg", 
                    "data": base64ImageData
                  }
                }
              ]
            }
          ],
           "generationConfig": {
            "temperature": 0.2, 
            "topK": 1, // Setting topK to 1 can make it more deterministic
            "topP": 0.9,
            "maxOutputTokens": 1024, 
          }
        }),
      ).timeout(const Duration(seconds: 120)); 

      print("Gemini API Response Status: ${response.statusCode}");
      // print("Gemini API Response Body for Debugging Parsing:\n${response.body}"); 

      if (mounted) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> resultData = jsonDecode(response.body);
          
          if (resultData.containsKey('candidates') &&
              (resultData['candidates'] as List).isNotEmpty &&
              resultData['candidates'][0]['content']?['parts']?[0]?['text'] != null) {
            
            String rawText = resultData['candidates'][0]['content']['parts'][0]['text'].toString().trim();
            print("Gemini Raw Text Output for Parsing:\n$rawText"); 
            
            setState(() {
              _analysisDetails = WasteAnalysisDetails.fromRawText(rawText);
            });

          } else {
            _errorMessage = "Could not parse Gemini's response structure.";
             print("Unexpected Gemini response structure: ${response.body}");
          }
        } else {
          String serverError = response.body;
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            serverError = errorData['error']?['message']?.toString() ?? response.body;
          } catch (_) {
            // Keep serverError as response.body
          }
          setState(() {
            _errorMessage = "Gemini API error (${response.statusCode}): $serverError";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "An unexpected error occurred: ${e.toString()}";
        });
      }
      print("Generic Exception: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

 @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Categorization'), // Updated title
        backgroundColor: theme.colorScheme.surfaceVariant, // Lighter app bar
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              "Upload an image to categorize agricultural waste", // Subtitle like target
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Mimicking the "Upload Waste Image" box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                    child: Center(
                      child: _image == null
                          ? Container(
                              height: 180, // Adjusted height
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                // Dashed border can be complex, using solid for now
                                // border: Border.all(color: Colors.grey[400]!, width: 1.5), 
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload_outlined, size: 60, color: theme.colorScheme.primary),
                                  const SizedBox(height: 8),
                                  const Text("Upload Waste Image", style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_image!, height: 180, width: double.infinity, fit: BoxFit.cover),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                   // "OR Select Crop Type" - This is a feature not yet implemented with Gemini
                  // For now, we focus on image analysis. This could be a future enhancement.
                  // Row(
                  //   children: <Widget>[
                  //     Expanded(child: Divider()),
                  //     Padding(
                  //       padding: EdgeInsets.symmetric(horizontal: 8.0),
                  //       child: Text("OR", style: TextStyle(color: Colors.grey)),
                  //     ),
                  //     Expanded(child: Divider()),
                  //   ],
                  // ),
                  // const SizedBox(height: 12),
                  // Text("Select Crop Type (Coming Soon)", style: TextStyle(color: Colors.grey)),
                  // const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Use Camera'),
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40), // Full width
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_image == null || _isLoading) ? null : _classifyWasteWithGemini,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16), // Taller button
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), 
                ),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)),
                        SizedBox(width: 16),
                        Text("Analyzing Waste..."),
                      ],
                    )
                  : const Text('Analyze Waste'),
            ),
            const SizedBox(height: 24),
            if (_analysisDetails != null)
              _buildAnalysisResultsCard(_analysisDetails!, theme), // Using the new card
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // New Analysis Results Card - to match target UI
  Widget _buildAnalysisResultsCard(WasteAnalysisDetails details, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Analysis Results", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              // "Close" button - not functional yet, can be added if this is a dialog
              // TextButton(onPressed: (){}, child: Text("Close"))
            ],
          ),
          const Divider(height: 24),
          
          Text("Waste Type", style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(
            details.primaryCategory ?? "Not specified",
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          ),
          // Confidence is not directly available from Gemini text API like this
          // If you had a way to get it, you could add:
          // Align(
          //   alignment: Alignment.centerRight,
          //   child: Chip(label: Text("93.8% confidence"), backgroundColor: Colors.blue[100]),
          // ),
          const SizedBox(height: 16),

          if (details.specificItems != null && details.specificItems!.isNotEmpty) ...[
            Text("Specific Items Identified:", style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(details.specificItems!, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
          ],
          
          if (details.suggestedUses.isNotEmpty) ...[
            Text("Suggested Uses", style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 6.0,
              children: details.suggestedUses.map((use) => Chip(
                label: Text(use),
                backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                labelStyle: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontSize: 13),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],

          if (details.composition.isNotEmpty) ...[
            Text("Composition", style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            ...details.composition.entries.map((entry) {
              double percentage = 0.0;
              final valueString = entry.value.replaceAll(RegExp(r'[^0-9.-]'),''); // Extract numbers
              List<String> rangeParts = valueString.split('-');
              try {
                if (rangeParts.length == 2) { // Handle ranges like "35-45"
                  percentage = (double.parse(rangeParts[0]) + double.parse(rangeParts[1])) / 2.0 / 100.0;
                } else if (rangeParts.isNotEmpty && rangeParts[0].isNotEmpty) {
                  percentage = double.parse(rangeParts[0]) / 100.0;
                }
              } catch (e) { /* ignore parsing errors */ }
              percentage = percentage.clamp(0.0, 1.0); // Ensure it's between 0 and 1

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${entry.key}: ${entry.value}", style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 3),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary.withOpacity(0.7)),
                      minHeight: 8, // Thicker bar
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],

          if (details.estimatedQuantity != null && details.estimatedQuantity!.isNotEmpty) ...[
            Text("Estimated Quantity:", style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(details.estimatedQuantity!, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
          ],

          if (details.conditionNotes != null && details.conditionNotes!.isNotEmpty) ...[
            Text("Condition/Notes:", style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(details.conditionNotes!, style: theme.textTheme.bodyLarge),
          ],

          // Fallback to show raw response if parsing was minimal
          if (details.primaryCategory == null && details.specificItems == null && details.suggestedUses.isEmpty && details.composition.isEmpty && details.rawResponse.isNotEmpty) ...[
            const SizedBox(height: 10),
            ExpansionTile(
              title: Text("Show Raw Gemini Response", style: TextStyle(color: theme.colorScheme.secondary)),
              childrenPadding: const EdgeInsets.all(8),
              children: [
                SelectableText(details.rawResponse, style: theme.textTheme.bodySmall),
              ],
            )
          ]
        ],
      ),
    );
  }

  // This old detail item builder is not used with the new card, but kept for reference if needed elsewhere
  // Widget _buildDetailItem(IconData icon, String label, String value, ThemeData theme) { ... }
}
