import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/orchid/menu/orchid_popup_menu_button.dart';
import 'models.dart';

class ModelSelectionButton extends StatefulWidget {
  final List<ModelInfo> models;
  final List<String> selectedModelIds;
  final Function(List<String>) updateModels;
  final bool multiSelectMode;

  const ModelSelectionButton({
    Key? key,
    required this.models,
    required this.selectedModelIds,
    required this.updateModels,
    required this.multiSelectMode,
  }) : super(key: key);

  @override
  State<ModelSelectionButton> createState() => _ModelSelectionButtonState();
}

class _ModelSelectionButtonState extends State<ModelSelectionButton> {
  final _menuWidth = 273.0;
  final _menuHeight = 50.0;
  final _textStyle = OrchidText.medium_16_025.copyWith(height: 2.0);
  bool _buttonSelected = false;

  String get _buttonText {
    if (widget.selectedModelIds.isEmpty) {
      return widget.multiSelectMode ? 'Select Models' : 'Select Model';
    }
    if (!widget.multiSelectMode || widget.selectedModelIds.length == 1) {
      final modelId = widget.selectedModelIds.first;
      return widget.models
          .firstWhere(
            (m) => m.id == modelId,
            orElse: () => ModelInfo(
              id: modelId,
              name: modelId,
              provider: '',
              apiType: '',
            ),
          )
          .name;
    }
    return '${widget.selectedModelIds.length} Models';
  }

  void _handleModelSelection(String modelId) {
    if (widget.multiSelectMode) {
      final newSelection = List<String>.from(widget.selectedModelIds);
      if (newSelection.contains(modelId)) {
        newSelection.remove(modelId);
      } else {
        newSelection.add(modelId);
      }
      widget.updateModels(newSelection);
    } else {
      widget.updateModels([modelId]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrchidPopupMenuButton<String>(
      width: null,
      height: 40,
      selected: _buttonSelected,
      backgroundColor: Colors.transparent,
      onSelected: (item) {
        setState(() {
          _buttonSelected = false;
        });
      },
      onCanceled: () {
        setState(() {
          _buttonSelected = false;
        });
      },
      itemBuilder: (itemBuilderContext) {
        setState(() {
          _buttonSelected = true;
        });

        if (widget.models.isEmpty) {
          return [
            PopupMenuItem<String>(
              enabled: false,
              height: _menuHeight,
              child: SizedBox(
                width: _menuWidth,
                child: Text('Enter an account to see models', style: _textStyle),
              ),
            ),
          ];
        }

        return widget.models.map((model) {
          final isSelected = widget.selectedModelIds.contains(model.id);
          
          return PopupMenuItem<String>(
            onTap: () => _handleModelSelection(model.id),
            height: _menuHeight,
            child: SizedBox(
              width: _menuWidth,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      model.name,
                      style: _textStyle.copyWith(
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                ],
              ),
            ),
          );
        }).toList();
      },
      child: SizedBox(
        height: 40,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _buttonText,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                ).button.white,
              ),
              Icon(
                Icons.arrow_drop_down,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
