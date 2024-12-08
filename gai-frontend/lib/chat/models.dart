import 'package:orchid/orchid/orchid.dart';

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

  String? getModelName(String? modelId) {
    if (modelId == null) return null;
    final model = allModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => ModelInfo(
        id: modelId,
        name: modelId,
        provider: '',
        apiType: '',
      ),
    );
    return model.name;
  }

  List<ModelInfo> get allModels {
    final List<ModelInfo> models = _modelsByProvider.values.expand((models) => models).toList();
    log('ModelsState.allModels returning ${models.length} models: ${models.toString().truncate(64)}');
    return models;
  }

  Future<void> fetchModelsForProvider(
    String providerId, 
    dynamic client,
  ) async {
    log('ModelsState: Fetching models for provider $providerId');
    _loadingProviders.add(providerId);
    _errors.remove(providerId);
    notifyListeners();

    try {
      final response = await client.listModels();
      log('ModelsState: Received model data from client: ${response.toString().truncate(64)}');
      
      // Convert the response map entries directly to ModelInfo objects
      final modelsList = response.entries.map((entry) => ModelInfo(
        id: entry.value.id,
        name: entry.value.name,
        provider: providerId,
        apiType: entry.value.apiType,
      )).toList();
      
      log('ModelsState: Created models list: ${modelsList.toString().truncate(64)}');

      _modelsByProvider[providerId] = modelsList.cast<ModelInfo>();
      log('ModelsState: Updated models for provider $providerId: ${modelsList.toString().truncate(64)}');
    } catch (e, stack) {
      log('ModelsState: Error fetching models: $e\n$stack');
      _errors[providerId] = e.toString();
    } finally {
      _loadingProviders.remove(providerId);
      notifyListeners();
      log('ModelsState: Notified listeners, current state: \n'
            'Models: ${_modelsByProvider.toString().truncate(64)}\n'
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

  void clear() {
    log('ModelsState: Clearing all models');
    _modelsByProvider.clear();
    _errors.clear();
    _loadingProviders.clear();
    notifyListeners();
  }

  bool get isAnyLoading => _loadingProviders.isNotEmpty;
  Set<String> get activeProviders => _modelsByProvider.keys.toSet();
}
