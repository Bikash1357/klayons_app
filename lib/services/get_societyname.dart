import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:klayons/config/api_config.dart';

// Society model class to hold all society details
class Society {
  final int id;
  final String name;
  final String address;

  Society({required this.id, required this.name, required this.address});

  factory Society.fromJson(Map<String, dynamic> json) {
    return Society(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

class GetSocietyname extends StatefulWidget {
  const GetSocietyname({super.key});

  @override
  State<GetSocietyname> createState() => _GetSocietynameState();
}

class _GetSocietynameState extends State<GetSocietyname> {
  List<Society> societies = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchSocieties();
  }

  Future<void> fetchSocieties() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      String url = ApiConfig.getFullUrl(ApiConfig.getSocieties);
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          societies = data
              .map((societyJson) => Society.fromJson(societyJson))
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load societies: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Society Names'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Refresh button
              CupertinoButton(
                onPressed: isLoading ? null : fetchSocieties,
                child: const Text('Refresh'),
              ),
              const SizedBox(height: 16),

              // Content area
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 20));
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage!,
              style: const TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: fetchSocieties,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (societies.isEmpty) {
      return const Center(
        child: Text(
          'No societies found',
          style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
        ),
      );
    }

    return ListView.builder(
      itemCount: societies.length,
      itemBuilder: (context, index) {
        final society = societies[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
          ),
          child: CupertinoListTile(
            title: Text(
              society.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'ID: ${society.id}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  society.address,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.systemGrey,
            ),
            onTap: () {
              // Handle tap - you can navigate or perform actions here
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('Society Details'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${society.id}'),
                      const SizedBox(height: 8),
                      Text('Name: ${society.name}'),
                      const SizedBox(height: 8),
                      Text('Address: ${society.address}'),
                    ],
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('OK'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
