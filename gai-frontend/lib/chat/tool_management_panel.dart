import 'package:flutter/material.dart';
import 'package:orchid/chat/provider_manager.dart';
import 'package:orchid/chat/tool_definition.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/orchid/orchid_colors.dart';

// A panel for enabling/disabling tools to be used in the chat
class ToolManagementPanel extends StatefulWidget {
  const ToolManagementPanel({Key? key}) : super(key: key);

  @override
  State<ToolManagementPanel> createState() => _ToolManagementPanelState();
}

class _ToolManagementPanelState extends State<ToolManagementPanel> {
  final ProviderManager _providerManager = ProviderManager.instance;
  // Keep a list of keys for each tool item so we can force rebuild
  final List<GlobalKey<_ToolToggleItemState>> _toolItemKeys = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Tools',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          
          // Tool list with toggle switches
          Expanded(
            child: ValueListenableBuilder<List<ToolDefinition>>(
              valueListenable: _providerManager.availableToolsNotifier,
              builder: (context, tools, _) {
                if (tools.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tools available',
                      style: TextStyle(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }
                
                // Clear and recreate keys if the tools list changes
                if (_toolItemKeys.length != tools.length) {
                  _toolItemKeys.clear();
                  for (int i = 0; i < tools.length; i++) {
                    _toolItemKeys.add(GlobalKey<_ToolToggleItemState>());
                  }
                }
                
                return ListView.builder(
                  itemCount: tools.length,
                  itemBuilder: (context, index) {
                    final tool = tools[index];
                    return _ToolToggleItem(
                      key: _toolItemKeys[index],
                      tool: tool,
                    );
                  },
                );
              },
            ),
          ),
          
          // Quick enable/disable buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  // Force rebuild of items immediately
                  setState(() {
                    // First update provider manager state
                    _providerManager.enableAllTools();
                  });
                  
                  // To ensure ListView.builder items update, we need to force rebuild all of them
                  // This is better than relying just on the ValueListenable
                  for (var i = 0; i < _toolItemKeys.length; i++) {
                    final key = _toolItemKeys[i];
                    if (key.currentState != null) {
                      key.currentState!.setState(() {});
                    }
                  }
                  
                  // Update the value and notify listeners as well
                  final allTools = _providerManager.getAllAvailableTools();
                  _providerManager.availableToolsNotifier.value = List.from(allTools);
                  _providerManager.availableToolsNotifier.notifyListeners();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white30),
                ),
                child: const Text('Enable All'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  // Force rebuild of items immediately
                  setState(() {
                    // First update provider manager state
                    _providerManager.disableAllTools();
                  });
                  
                  // To ensure ListView.builder items update, we need to force rebuild all of them
                  // This is better than relying just on the ValueListenable
                  for (var i = 0; i < _toolItemKeys.length; i++) {
                    final key = _toolItemKeys[i];
                    if (key.currentState != null) {
                      key.currentState!.setState(() {});
                    }
                  }
                  
                  // Update the value and notify listeners as well
                  final allTools = _providerManager.getAllAvailableTools();
                  _providerManager.availableToolsNotifier.value = List.from(allTools);
                  _providerManager.availableToolsNotifier.notifyListeners();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white30),
                ),
                child: const Text('Disable All'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolToggleItem extends StatefulWidget {
  final ToolDefinition tool;
  
  const _ToolToggleItem({super.key, required this.tool});
  
  @override
  _ToolToggleItemState createState() => _ToolToggleItemState();
}

class _ToolToggleItemState extends State<_ToolToggleItem> {
  final ProviderManager _providerManager = ProviderManager.instance;
  
  // We don't store state locally - always use the provider manager's state
  bool get _enabled => _providerManager.isToolEnabled(widget.tool.name);
  
  @override
  void initState() {
    super.initState();
    // Listen for changes to the tools list
    _providerManager.availableToolsNotifier.addListener(_onToolsChanged);
  }
  
  @override
  void dispose() {
    // Clean up listener when widget is removed
    _providerManager.availableToolsNotifier.removeListener(_onToolsChanged);
    super.dispose();
  }
  
  void _onToolsChanged() {
    // Force rebuild when tools list changes
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  void didUpdateWidget(_ToolToggleItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force rebuild if the tool changes
    if (oldWidget.tool.name != widget.tool.name) {
      setState(() {});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Find which provider offers this tool
    final provider = _providerManager.getToolProvider(widget.tool.name);
    final providerName = provider?.name ?? 'Unknown';
    
    return Card(
      color: Colors.grey.shade900,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            // Tool info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tool.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.tool.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: OrchidColors.new_purple,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          providerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.tool.parameters.properties.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${widget.tool.parameters.properties.length} params',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            
            // Toggle switch
            Switch(
              value: _enabled, // Now using a getter that always reflects current state
              onChanged: (value) {
                // Update provider manager first
                if (value) {
                  _providerManager.enableTool(widget.tool.name);
                } else {
                  _providerManager.disableTool(widget.tool.name);
                }
                
                // Force local rebuild
                setState(() {
                  // State is derived from provider manager via getter
                });
                
                // Also trigger global UI update
                _providerManager.availableToolsNotifier.notifyListeners();
              },
              activeColor: OrchidColors.purple_bright,
            ),
          ],
        ),
      ),
    );
  }
}