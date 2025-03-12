import 'package:flutter/material.dart';
import 'package:orchid/chat/provider_manager.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/orchid/orchid_colors.dart';

class ProviderManagementDialog extends StatefulWidget {
  const ProviderManagementDialog({Key? key}) : super(key: key);

  @override
  _ProviderManagementDialogState createState() => _ProviderManagementDialogState();
}

class _ProviderManagementDialogState extends State<ProviderManagementDialog> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final ProviderManager _providerManager = ProviderManager.instance;
  
  @override
  void initState() {
    super.initState();
    // Set default name
    _nameController.text = 'Provider';
  }
  
  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.black,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Tool Providers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Current providers list with scrolling
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: _buildProviderList(),
            ),
            
            const SizedBox(height: 24),
            const Text(
              'Add New Provider',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            // Provider URL field
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Provider URL',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'wss://provider-url.example.com/billing',
                hintStyle: TextStyle(color: Colors.white30),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: OrchidColors.purple_bright),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Provider name field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Provider Name',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'My Tool Provider',
                hintStyle: TextStyle(color: Colors.white30),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: OrchidColors.purple_bright),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OrchidColors.new_purple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (_urlController.text.isNotEmpty) {
                      final url = _urlController.text.trim();
                      final name = _nameController.text.trim().isNotEmpty 
                          ? _nameController.text.trim() 
                          : 'Tool Provider';
                      
                      // Add the provider - capabilities will be auto-detected
                      _providerManager.addToolProvider(url, name);
                      
                      // Clear fields and refresh
                      _urlController.clear();
                      _nameController.text = 'Provider';
                      setState(() {}); // Refresh the UI
                    }
                  },
                  child: const Text('Add Provider'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProviderList() {
    // Get all providers, not just connected ones
    final providers = _providerManager.allProviders;
    
    if (providers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: const Text(
          'No providers configured',
          style: TextStyle(
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return Card(
          color: Colors.grey.shade900,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              provider.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.wsUrl,
                  style: TextStyle(color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    // We need to use conditional spreading with collection-if to handle multiple widgets
                    ...[
                      // Capability badges - using if-else pattern
                      if (provider.isToolsOnlyProvider)
                        _buildCapabilityBadge('TOOLS-ONLY', Colors.deepOrange)
                      else if (provider.supportsInference)
                        _buildCapabilityBadge('INFERENCE', Colors.blue),
                        
                      // Additional badges - using separate if statements
                      if (provider.supportsTools && !provider.isToolsOnlyProvider)
                        _buildCapabilityBadge('TOOLS', OrchidColors.new_purple),
                        
                      if (!provider.supportsInference && !provider.supportsTools)
                        _buildCapabilityBadge('CONNECTING...', Colors.orange),
                        
                      // Connection status badge - using if-else
                      if (provider.connected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CONNECTED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DISCONNECTED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
                // Tool count (if connected and has tools)
                if (provider.connected && provider.availableTools.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${provider.availableTools.length} tools available',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                // Model count (if supports inference)
                if (provider.supportsInference)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_providerManager.modelsState.getModelsForProvider(provider.id).length} models available',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.black,
                    title: const Text('Remove Provider', style: TextStyle(color: Colors.white)),
                    content: Text(
                      'Are you sure you want to remove "${provider.name}"?',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _providerManager.removeProvider(provider.id);
                          setState(() {}); // Refresh the UI
                        },
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCapabilityBadge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 4, right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}