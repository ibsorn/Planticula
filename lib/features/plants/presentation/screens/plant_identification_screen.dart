import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/core/services/plant_identification_service.dart';
import 'package:planticula/core/theme/app_colors.dart';
import 'package:planticula/core/theme/app_dimens.dart';
import 'package:planticula/features/plants/presentation/screens/plant_editor_screen.dart';

/// Pantalla para identificar plantas mediante foto
///
/// Flujo:
/// 1. Usuario selecciona/captura imagen
/// 2. Preview con opción de retomar/confirmar
/// 3. Procesamiento con IA
/// 4. Navegación a pantalla de revisión
class PlantIdentificationScreen extends StatefulWidget {
  const PlantIdentificationScreen({super.key});

  @override
  State<PlantIdentificationScreen> createState() =>
      _PlantIdentificationScreenState();
}

class _PlantIdentificationScreenState extends State<PlantIdentificationScreen> {
  final _identificationService = GetIt.instance<PlantIdentificationService>();
  final _picker = ImagePicker();

  Uint8List? _selectedImageBytes;
  bool _isProcessing = false;
  String? _errorMessage;

  // Estado del progreso de identificación
  String _progressMessage = '';
  double _progressValue = 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Identificar planta 📸'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppDimens.screenPadding,
          child: _selectedImageBytes == null
              ? _buildSelectionView(theme)
              : _buildPreviewView(theme),
        ),
      ),
    );
  }

  /// Vista inicial: Opciones para seleccionar imagen
  ///
  /// Diseño 100% responsive:
  /// - Siempre usa scroll para evitar overflow en cualquier dispositivo
  /// - Contenido centrado verticalmente cuando hay espacio extra
  /// - Se adapta a diferentes tamaños de fuente y densidades de pantalla
  Widget _buildSelectionView(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxHeight < 600;
        final iconSize = isSmallScreen ? 48.0 : 64.0;
        final verticalSpacing = isSmallScreen ? AppDimens.lg : AppDimens.xl;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: AppDimens.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Espacio flexible superior que empuja el contenido al centro
                    // cuando hay espacio disponible
                    Flexible(
                      flex: 2,
                      child: Container(),
                    ),

                    // Ilustración/Icono grande - adaptativo
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? AppDimens.xl : AppDimens.xxl),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: iconSize,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    SizedBox(height: verticalSpacing),

                    // Título - siempre respetando overflow
                    Text(
                      '¿Tienes una foto de tu planta?',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                    ),

                    const SizedBox(height: AppDimens.md),

                    // Descripción - adaptativa
                    Text(
                      'La IA identificará la especie, tamaño, etapa de crecimiento y más detalles automáticamente.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: verticalSpacing),

                    // Botón: Cámara - siempre visible y accesible
                    FilledButton.icon(
                      onPressed: _isProcessing ? null : _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text(
                        'Tomar foto',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),

                    const SizedBox(height: AppDimens.md),

                    // Botón: Galería - siempre visible y accesible
                    OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _pickFromGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text(
                        'Elegir de la galería',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),

                    // Espacio flexible medio
                    Flexible(
                      flex: 3,
                      child: Container(),
                    ),

                    // Tips para mejor identificación - siempre al fondo pero sin overflow
                    Card(
                      margin: const EdgeInsets.only(bottom: AppDimens.md),
                      child: Padding(
                        padding: AppDimens.cardPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lightbulb_outline,
                                    size: 18, color: AppColors.sun),
                                const SizedBox(width: AppDimens.sm),
                                Expanded(
                                  child: Text(
                                    'Consejos para mejores resultados',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimens.sm),
                            _buildTip('📸', 'Buena iluminación'),
                            _buildTip('🌿', 'Enfoca hojas y tallo'),
                            _buildTip('🪴', 'Incluye la maceta'),
                          ],
                        ),
                      ),
                    ),

                    // Espacio inferior mínimo para safe area
                    const SizedBox(height: AppDimens.sm),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: AppDimens.sm),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Widget de progreso detallado durante identificación
  Widget _buildProgressIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de progreso lineal
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.sm),
            child: LinearProgressIndicator(
              value: _progressValue > 0 ? _progressValue : null,
              minHeight: 6,
              backgroundColor: AppColors.primarySoft,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppDimens.md),
          // Mensaje de etapa actual
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(width: AppDimens.md),
              Flexible(
                child: Text(
                  _progressMessage.isNotEmpty
                      ? _progressMessage
                      : 'Preparando...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Vista de preview: Muestra la imagen seleccionada con opciones
  Widget _buildPreviewView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preview de imagen
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.md),
            child: Image.memory(
              _selectedImageBytes!,
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(height: AppDimens.lg),

        // Indicador de procesamiento o botones
        if (_isProcessing) ...[
          _buildProgressIndicator(theme),
        ] else ...[
          // Mensaje de error si existe
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: BorderRadius.circular(AppDimens.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.md),
          ],

          // Botones de acción - 100% responsive sin overflow
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;

              // En pantallas muy estrechas (< 340): apilados verticalmente
              if (availableWidth < 340) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: _processImage,
                      icon: const Icon(Icons.auto_awesome, size: 20),
                      label: const Text(
                        'Identificar',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimens.md,
                          horizontal: AppDimens.sm,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.sm),
                    OutlinedButton.icon(
                      onPressed: _showImageSourceOptions,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text(
                        'Cambiar',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimens.md,
                          horizontal: AppDimens.sm,
                        ),
                      ),
                    ),
                  ],
                );
              }

              // En pantallas normales: fila con distribución inteligente
              // Usamos Wrap como fallback si el Row no cabe
              final isCompact = availableWidth < 400;

              return Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Botón Cambiar - flex proporcional según espacio
                  Flexible(
                    flex: isCompact ? 1 : 2,
                    fit: FlexFit.tight,
                    child: OutlinedButton.icon(
                      onPressed: _showImageSourceOptions,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(
                        isCompact ? 'Cambiar' : 'Cambiar foto',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: AppDimens.md,
                          horizontal: isCompact ? AppDimens.sm : AppDimens.md,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.md),
                  // Botón Identificar - siempre con más espacio
                  Flexible(
                    flex: isCompact ? 2 : 3,
                    fit: FlexFit.tight,
                    child: FilledButton.icon(
                      onPressed: _processImage,
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: Text(
                        isCompact ? 'Identificar' : 'Identificar planta',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          vertical: AppDimens.md,
                          horizontal: isCompact ? AppDimens.sm : AppDimens.md,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],

        const SizedBox(height: AppDimens.md),
      ],
    );
  }

  /// Muestra opciones para cambiar la fuente de la imagen
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppDimens.md),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar nueva foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Elegir de galería'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Eliminar foto',
                    style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _selectedImageBytes = null);
              },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Captura foto con la cámara
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _errorMessage = null;
        });
      }
    } on PlatformException catch (e) {
      _showError('No se pudo acceder a la cámara: ${e.message}');
    }
  }

  /// Selecciona imagen de la galería
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _errorMessage = null;
        });
      }
    } on PlatformException catch (e) {
      _showError('No se pudo acceder a la galería: ${e.message}');
    }
  }

  /// Procesa la imagen con el servicio de identificación
  Future<void> _processImage() async {
    if (_selectedImageBytes == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _progressMessage = 'Preparando...';
      _progressValue = 0.0;
    });

    try {
      final result = await _identificationService.identifyFromImage(
        _selectedImageBytes!,
        onProgress: (stage, message, progress) {
          if (mounted) {
            setState(() {
              _progressMessage = message;
              _progressValue = progress;
            });
          }
        },
      );

      if (!mounted) return;

      if (result.isSuccessful && result.species != null) {
        context.push(
          AppConstants.routePlantEditor,
          extra: {
            'mode': PlantEditorMode.aiAssisted,
            'identificationResult': result,
            'imageBytes': _selectedImageBytes!,
          },
        );
      } else {
        setState(() {
          _errorMessage = result.errorMessage ??
              'No se pudo identificar la planta. Intenta con otra foto.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al procesar: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
