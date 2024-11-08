import 'package:flutter/foundation.dart';

class ModelInfo {
  final String id;          
  final String name;        
  final String provider;    
  final String apiType;     
  
  ModelInfo({
    required this.id,
    required this.name,
    required this.provider,
    required this.apiType,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json, String providerId) {
    return ModelInfo(
      id: json['id'],
      name: json['name'],
      provider: providerId,
      apiType: json['api_type'],
    );
  }

  @override
  String toString() => 'ModelInfo(id: $id, name: $name, provider: $provider)';
}

class ModelsState extends ChangeNotifier {
  final _modelsByProvider = <String, List<ModelInfo>>{};
  final _loadingProviders = <String>{};
  final _errors = <String, String>{};

  bool isLoading(String providerId) => _loadingProviders.contains(providerId);
  String? getError(String providerId) => _errors[providerId];
  
  List<ModelInfo> getModelsForProvider(String providerId) {
    return _modelsByProvider[providerId] ?? [];
  }

  List<ModelInfo> get allModels {
    final models = _modelsByProvider.values.expand((models) => models).toList();
    print('ModelsState.allModels returning ${models.length} models: $models');
    return models;
  }

  Future<void> fetchModelsForProvider(
    String providerId, 
    dynamic client,
  ) async {
    print('ModelsState: Fetching models for provider $providerId');
    _loadingProviders.add(providerId);
    _errors.remove(providerId);
    notifyListeners();

    try {
      final response = await client.listModels();
      print('ModelsState: Received model data from client: $response');
      
      // Convert the response map entries directly to ModelInfo objects
      final modelsList = response.entries.map((entry) => ModelInfo(
        id: entry.value.id,
        name: entry.value.name,
        provider: providerId,
        apiType: entry.value.apiType,
      )).toList();
      
      print('ModelsState: Created models list: $modelsList');
      
      _modelsByProvider[providerId] = modelsList;
      print('ModelsState: Updated models for provider $providerId: $modelsList');
    } catch (e, stack) {
      print('ModelsState: Error fetching models: $e\n$stack');
      _errors[providerId] = e.toString();
    } finally {
      _loadingProviders.remove(providerId);
      notifyListeners();
      print('ModelsState: Notified listeners, current state: \n'
            'Models: ${_modelsByProvider}\n'
            'Loading: $_loadingProviders\n'
            'Errors: $_errors');
    }
  }

  void clearProviderModels(String providerId) {
    _modelsByProvider.remove(providerId);
    _errors.remove(providerId);
    _loadingProviders.remove(providerId);
    notifyListeners();
  }

  bool get isAnyLoading => _loadingProviders.isNotEmpty;
  Set<String> get activeProviders => _modelsByProvider.keys.toSet();
}
