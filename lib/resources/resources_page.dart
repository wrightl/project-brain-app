import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:projectbrain/models/resource.dart';
import 'package:projectbrain/services/resource_service.dart';
import 'package:projectbrain/core/di/injection_container.dart';
import 'package:projectbrain/subscription/subscription_provider.dart';
import 'package:projectbrain/subscription/widgets/upgrade_prompt.dart';
import 'package:projectbrain/models/subscription.dart';

/// Resources page for managing user files
class ResourcesPage extends StatefulWidget {
  const ResourcesPage({super.key});

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> {
  final ResourceService _resourceService = sl<ResourceService>();
  List<Resource> _resources = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resources = await _resourceService.getResources();
      setState(() {
        _resources = resources;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load resources: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadFiles() async {
    // Check subscription limits
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    final fileCountLimit = subscriptionProvider.getFileCountLimit();
    final storageLimitMB = subscriptionProvider.getFileStorageLimitMB();
    
    // Get current usage
    try {
      await subscriptionProvider.refresh();
      final usage = subscriptionProvider.usage;
      if (usage == null) return;
      
      // Check file count limit
      if (fileCountLimit != null) {
        // Note: We'd need to get current file count from resources list
        // For now, we'll rely on backend enforcement
      }
      
      // Check storage limit
      if (storageLimitMB != null) {
        final currentStorageMB = usage.fileStorage.megabytes;
        if (currentStorageMB >= storageLimitMB) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => UpgradePromptDialog(
                requiredTier: SubscriptionTier.pro,
                featureName: 'File storage',
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      // If we can't check usage, proceed anyway (backend will enforce)
      debugPrint('Could not check usage: $e');
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _isUploading = true;
          _errorMessage = null;
          _successMessage = null;
        });

        // Convert PlatformFile to File
        final files = result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();

        if (files.isEmpty) {
          setState(() {
            _errorMessage = 'No valid files selected';
            _isUploading = false;
          });
          return;
        }

        // Check if new files would exceed storage limit
        if (storageLimitMB != null) {
          try {
            await subscriptionProvider.refresh();
            final usage = subscriptionProvider.usage;
            if (usage == null) {
              setState(() {
                _isUploading = false;
              });
              return;
            }
            final totalSizeMB = files.fold<double>(
              0,
              (sum, file) => sum + (file.lengthSync() / (1024 * 1024)),
            );
            
            if (usage.fileStorage.megabytes + totalSizeMB > storageLimitMB) {
              setState(() {
                _errorMessage = 'Upload would exceed storage limit. Please upgrade your plan.';
                _isUploading = false;
              });
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => UpgradePromptDialog(
                    requiredTier: SubscriptionTier.pro,
                    featureName: 'File storage',
                  ),
                );
              }
              return;
            }
          } catch (e) {
            // If we can't check, proceed anyway (backend will enforce)
            debugPrint('Could not check storage: $e');
          }
        }

        await _resourceService.uploadFiles(files);

        setState(() {
          _successMessage = 'Successfully uploaded ${files.length} file(s)';
          _isUploading = false;
        });

        // Reload resources after upload
        await _loadResources();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_successMessage!),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload files: ${e.toString()}';
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _deleteResource(Resource resource) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resource'),
        content:
            Text('Are you sure you want to delete "${resource.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _errorMessage = null;
          _successMessage = null;
        });

        await _resourceService.deleteResource(resource.id);

        setState(() {
          _successMessage = 'Successfully deleted "${resource.fileName}"';
        });

        // Reload resources after deletion
        await _loadResources();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_successMessage!),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to delete resource: ${e.toString()}';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Resources',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _uploadFiles,
              tooltip: 'Upload files',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadResources,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _resources.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadResources,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _resources.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No resources found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload files to get started',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _uploadFiles,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Files'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadResources,
                      child: ListView.builder(
                        itemCount: _resources.length,
                        itemBuilder: (context, index) {
                          final resource = _resources[index];
                          return ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(resource.fileName),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteResource(resource),
                              tooltip: 'Delete',
                            ),
                            onTap: () {
                              // Could add file preview or download functionality here
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
