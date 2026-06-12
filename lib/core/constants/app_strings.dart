/// Centralized UI strings for Planticula.
///
/// Organized by feature/screen to make localization easy in the future.
/// Usage: AppStrings.loginTitle, AppStrings.plantsTitle, etc.
class AppStrings {
  AppStrings._();

  // ── General ──────────────────────────────────────────────────────────────────
  static const String appName = 'Planticula';
  static const String appSubtitle = 'Tu asistente de cultivo inteligente';
  static const String cancel = 'Cancelar';
  static const String save = 'Guardar';
  static const String delete = 'Eliminar';
  static const String retry = 'Reintentar';
  static const String close = 'Cerrar';
  static const String confirm = 'Confirmar';
  static const String loading = 'Cargando...';
  static const String error = 'Error';
  static const String success = 'Éxito';
  static const String yes = 'Sí';
  static const String no = 'No';
  static const String unknownError = 'Error desconocido';
  static const String send = 'Enviar';
  static const String change = 'Cambiar';
  static const String report = 'Reportar';

  // ── Navigation (bottom bar) ───────────────────────────────────────────────────
  static const String navPlants = 'Plantas';
  static const String navAlerts = 'Alertas';
  static const String navMarket = 'Mercado';
  static const String navGuides = 'Guias';
  static const String navProfile = 'Perfil';

  // ── Auth ─────────────────────────────────────────────────────────────────────
  static const String loginTitle = 'Iniciar Sesión';
  static const String loginButton = 'Iniciar Sesión';
  static const String loginSubtitle = 'Tu asistente de cultivo inteligente';
  static const String loginNoAccount = '¿No tienes cuenta?';
  static const String loginRegisterLink = 'Regístrate';
  static const String loginForgotPassword = '¿Olvidaste tu contraseña?';

  static const String registerTitle = 'Crear Cuenta';
  static const String registerWelcome = '¡Bienvenido a Planticula!';
  static const String registerSubtitle =
      'Crea tu cuenta para comenzar a cuidar tus plantas';
  static const String registerButton = 'Crear Cuenta';
  static const String registerHasAccount = '¿Ya tienes cuenta?';
  static const String registerLoginLink = 'Inicia sesión';
  static const String registerTermsCheckbox =
      'Acepto los términos y condiciones y la política de privacidad';
  static const String registerTermsError =
      'Debes aceptar los términos y condiciones';

  static const String fieldEmail = 'Email';
  static const String fieldEmailHint = 'tu@email.com';
  static const String fieldEmailRequired = 'El email es requerido';
  static const String fieldEmailInvalid = 'Email inválido';
  static const String fieldPassword = 'Contraseña';
  static const String fieldPasswordHint = '********';
  static const String fieldPasswordRequired = 'La contraseña es requerida';
  static const String fieldPasswordMinLength = 'Mínimo 6 caracteres';
  static const String fieldPasswordConfirm = 'Confirmar Contraseña';
  static const String fieldPasswordConfirmError = 'Confirma tu contraseña';
  static const String fieldPasswordMismatch = 'Las contraseñas no coinciden';
  static const String fieldName = 'Nombre';
  static const String fieldNameHint = 'Tu nombre';
  static const String fieldNameRequired = 'El nombre es requerido';
  static const String fieldNameTooShort = 'El nombre debe tener al menos 2 caracteres';

  static const String forgotPasswordTitle = 'Restablecer contraseña';
  static const String forgotPasswordBody =
      'Introduce tu email y te enviaremos un enlace para restablecer tu contraseña.';
  static const String resetPasswordEmailSent =
      'Se ha enviado un correo para restablecer tu contraseña. Revisa tu bandeja de entrada.';

  // ── Auth errors (translated from Supabase English) ────────────────────────────
  static const String authErrorInvalidCredentials =
      'Email o contraseña incorrectos';
  static const String authErrorEmailAlreadyInUse =
      'Este email ya está registrado. ¿Quieres iniciar sesión?';
  static const String authErrorEmailNotConfirmed =
      'Debes confirmar tu email antes de iniciar sesión. Revisa tu bandeja de entrada.';
  static const String authErrorTooManyRequests =
      'Demasiados intentos. Por favor espera unos minutos antes de volver a intentarlo.';
  static const String authErrorNetwork =
      'Sin conexión a internet. Comprueba tu red y vuelve a intentarlo.';
  static const String authErrorWeakPassword =
      'La contraseña es demasiado débil. Usa al menos 8 caracteres con letras y números.';
  static const String authErrorUserNotFound =
      'No existe ninguna cuenta con ese email.';
  static const String authErrorSessionExpired =
      'Tu sesión ha expirado. Por favor inicia sesión de nuevo.';

  // ── Plants ────────────────────────────────────────────────────────────────────
  static const String plantsTitle = 'Mis Plantas';
  static const String plantsSearchHint = 'Buscar plantas...';
  static const String plantsAddButton = 'Añadir';
  static const String plantsAddPlantButton = 'Añadir Planta';
  static const String plantsEmptyTitle = 'No tienes plantas aún';
  static const String plantsEmptySubtitle =
      '¡Añade tu primera planta para comenzar a cuidarla!';
  static const String plantsErrorRetry = 'Reintentar';

  // Plant card watering states
  static const String plantNeedsWatering = '¡Necesita riego!';
  static const String plantWateringBadge = 'Riego';
  static const String plantWateringToday = 'Riego hoy';
  static const String plantWateringTomorrow = 'Riego mañana';

  // Plant detail
  static const String plantNeedsWateringBadge = 'Necesita riego';
  static const String plantNextWateringLabel = 'Proximo riego';
  static const String plantWateringFrequencyLabel = 'Frecuencia';
  static const String plantWateringAmountLabel = 'Cantidad';
  static const String plantPotLabel = 'Maceta';
  static const String plantWaterNowButton = 'Regar ahora';
  static const String plantRegisterWateringButton = 'Registrar riego';
  static const String plantNotScheduled = 'No programado';
  static const String plantWateringToday2 = 'Hoy';
  static const String plantWateringTomorrow2 = 'Manana';

  static const String plantSectionWatering = 'Riego';
  static const String plantSectionSunlight = 'Sol necesario';
  static const String plantSectionGrowth = 'Crecimiento';
  static const String plantSectionSpeciesInfo = 'Sobre esta especie';
  static const String plantSectionNotes = 'Notas';
  static const String plantAdultLabel = 'Planta adulta';
  static const String plantSpeciesNoData = 'No hay datos de la especie';

  static const String plantWeatherCurrentPrefix = 'Clima actual: ';
  static const String plantRainForecastPrefix = 'Lluvia prevista: ';
  static const String plantRainForecastSuffix = 'mm en 3 dias';

  // Watering dialog
  static const String wateringDialogTitle = 'Confirmar riego';
  static const String wateringDialogConfirmButton = 'Confirmar';
  static const String wateringRegistered = 'Riego registrado!';

  // Delete plant dialog
  static const String deletePlantDialogTitle = 'Eliminar planta?';
  static const String deletePlantDialogButton = 'Eliminar';

  // Transplant dialog
  static const String transplantDialogTitle = 'Registrar trasplante';
  static const String transplantChoosePot = 'Elige el nuevo tamaño de maceta:';
  static const String transplantRecommended = 'Recomendada';
  static const String transplantConfirmButton = 'Confirmar trasplante';
  static const String transplantRegistered = 'Trasplante a maceta';
  static const String transplantRegisteredSuffix = 'registrado!';

  // Species info chips
  static const String speciesDroughtTolerant = 'Tolerante a sequia';
  static const String speciesHumidityLoving = 'Necesita humedad';

  // Create plant screen
  static const String createPlantTitleStep0 = 'Que planta tienes?';
  static const String createPlantTitleStep1 = 'Cuentanos mas';
  static const String createPlantTitleVariety = 'Elige variedad';
  static const String createPlantSearchHint =
      'Buscar especie (ej: monstera, tomate...)';
  static const String createPlantNoResults = 'No se encontraron especies';
  static const String createPlantSelectVariety = 'Selecciona variedad:';
  static const String createPlantUseGeneric = 'Usar configuracion generica';
  static const String createPlantNameLabel = 'Ponle un nombre';
  static const String createPlantNameHint = 'Ej: Mi monstera del salon';
  static const String createPlantNameHelper =
      'Opcional - por defecto usa el nombre de la especie';
  static const String createPlantEnvironmentQuestion = 'Donde la tienes?';
  static const String createPlantIndoorLabel = 'Dentro de casa';
  static const String createPlantIndoorSubtitle = 'Salon, habitacion...';
  static const String createPlantOutdoorLabel = 'Fuera';
  static const String createPlantOutdoorSubtitle = 'Terraza, jardin, balcon';
  static const String createPlantPotQuestion = 'En que maceta esta?';
  static const String createPlantPotSubtitle =
      'El tamaño afecta la frecuencia y cantidad de agua por riego';
  static const String createPlantCareTitle = 'Asi la vamos a cuidar';
  static const String createPlantCareSubtitle =
      'Calculado segun la especie, ubicacion y tamaño';
  static const String createPlantWeatherAdjustments = 'Ajustes por clima';
  static const String createPlantSaveButton = 'Añadir planta';
  static const String createPlantSavingButton = 'Guardando...';
  static const String createPlantSuccess = 'Planta añadida correctamente';

  // Growth stage questions
  static const String growthStageQuestionCannabis = 'En que fase esta?';
  static const String growthStageQuestionEdible = 'Como esta tu planta?';
  static const String growthStageQuestionGeneric = 'Que tamaño tiene?';
  static const String growthStageQuestionSubtitle =
      'No te preocupes si no lo sabes exacto, es orientativo';
  static const String growthSucculentNote =
      'Los cactus y suculentas crecen muy lento. Ajustaremos el riego automaticamente.';

  static const String growthSeedlingCannabis = 'Recien plantada / germinando';
  static const String growthSeedlingCannabisSubtitle = 'Semilla o brote reciente';
  static const String growthJuvenileCannabis = 'Creciendo (vegetativo)';
  static const String growthJuvenileCannabisSubtitle =
      'Tiene tallos y hojas pero no flores';
  static const String growthAdultCannabis = 'En floracion';
  static const String growthAdultCannabisSubtitle =
      'Ya tiene cogollos formandose';

  static const String growthSeedlingEdible = 'Acaba de brotar';
  static const String growthSeedlingEdibleSubtitle =
      'Tiene pocas hojas pequeñas';
  static const String growthJuvenileEdible = 'Creciendo, sin frutos';
  static const String growthJuvenileEdibleSubtitle =
      'Tiene hojas pero todavia no da fruto ni flores';
  static const String growthAdultEdible = 'Ya da fruto o esta lista';
  static const String growthAdultEdibleSubtitle =
      'Tiene flores, frutos o se puede cosechar';

  static const String growthSeedlingGeneric = 'Pequeña / recien comprada';
  static const String growthSeedlingGenericSubtitle =
      'Brote, esqueje o planta muy joven';
  static const String growthJuvenileGeneric = 'Mediana, esta creciendo';
  static const String growthJuvenileGenericSubtitle =
      'Ya tiene varias hojas pero aun no es grande';
  static const String growthAdultGeneric = 'Grande, ya esta crecida';
  static const String growthAdultGenericSubtitle =
      'Planta adulta con buen tamaño';

  // ── Pest Alerts ──────────────────────────────────────────────────────────────
  static const String pestAlertsTitle = 'Alertas de Plagas';
  static const String pestAlertsTabNearby = 'Cercanas';
  static const String pestAlertsTabMine = 'Mis Alertas';
  static const String pestAlertsFilterTooltip = 'Filtros';
  static const String pestAlertsRefreshTooltip = 'Recargar';
  static const String pestAlertsReportButton = 'Reportar';
  static const String pestAlertsReportPlague = 'Reportar Plaga';

  static const String pestAlertsLocationRequired = 'Se requiere ubicación';
  static const String pestAlertsLocationSubtitle =
      'Necesitamos tu ubicación para mostrar alertas cercanas';
  static const String pestAlertsAllowLocation = 'Permitir Ubicación';

  static const String pestAlertsNearbyEmpty = 'No hay alertas cercanas';
  static const String pestAlertsAdjustFilters = 'Ajustar Filtros';
  static const String pestAlertsMyEmpty = 'No has reportado plagas';
  static const String pestAlertsMyEmptySubtitle =
      'Ayuda a la comunidad reportando plagas que observes';
  static const String pestAlertsReportLink = 'Reportar Plaga';

  static const String pestAlertsDeleteTitle = 'Eliminar alerta';
  static const String pestAlertsDeleteConfirm =
      '¿Estás seguro? Esta acción no se puede deshacer.';
  static const String pestAlertsDeleteConfirmLong =
      '¿Estás seguro de que deseas eliminar esta alerta? Esta acción no se puede deshacer.';
  static const String pestAlertsDeleteButton = 'Eliminar';
  static const String pestAlertsDeleted = 'Alerta eliminada';

  static const String pestAlertsMarkResolved = 'Marcar como resuelta';
  static const String pestAlertsDeleteAlert = 'Eliminar alerta';
  static const String pestAlertsConfirmSighting =
      'Confirmar que vi esta plaga';
  static const String pestAlertsConfirmed = '✅ Has confirmado esta alerta';
  static const String pestAlertsResolvedLabel = 'Plaga resuelta';

  // Report pest screen
  static const String reportPestTitle = 'Reportar Plaga';
  static const String reportPestPhotoLabel = 'Foto de la Plaga';
  static const String reportPestPhotoTap = 'Toca para añadir foto';
  static const String reportPestPhotoRecommended =
      'Recomendado para identificación';
  static const String reportPestTypeLabel = 'Tipo de Plaga';
  static const String reportPestCustomNameLabel = 'Nombre de la plaga';
  static const String reportPestCustomNameHint = 'Ej: Escarabajo de la hoja';
  static const String reportPestCustomNameRequired =
      'Especifica el nombre de la plaga';
  static const String reportPestSeverityLabel = 'Gravedad de la Infestación';
  static const String reportPestLocationLabel = 'Ubicación';
  static const String reportPestLocationNameLabel =
      'Nombre del lugar (opcional)';
  static const String reportPestLocationNameHint = 'Ej: Mi jardín trasero';
  static const String reportPestNotesLabel = 'Notas Adicionales';
  static const String reportPestNotesHint =
      'Describe lo que observas: comportamiento de la plaga, daños en la planta, etc.';
  static const String reportPestSubmitButton = 'Reportar Plaga';
  static const String reportPestSuccess = '✅ Alerta reportada correctamente';
  static const String reportPestLocationRequired =
      'Se requiere ubicación para reportar';
  static const String reportPestLocationGettingLocation =
      'Obteniendo ubicación...';
  static const String reportPestLocationError = 'Error de ubicación';
  static const String reportPestLocationObtained = 'Ubicación obtenida';

  // Pest alert detail screen
  static const String pestDetailLocationLabel = 'Ubicación';
  static const String pestDetailDistanceLabel = 'Distancia';
  static const String pestDetailReportedLabel = 'Reportado';
  static const String pestDetailConfirmationsLabel = 'Confirmaciones';
  static const String pestDetailObservationsLabel = 'Observaciones';
  static const String pestDetailActionsLabel = 'Acciones';
  static const String pestDetailNoPhoto = 'Sin foto disponible';

  // ── Marketplace ──────────────────────────────────────────────────────────────
  static const String marketplaceTitle = 'Marketplace';
  static const String marketplaceTabNearby = 'Cercanos';
  static const String marketplaceTabMyListings = 'Mis anuncios';
  static const String marketplaceTabFavorites = 'Favoritos';
  static const String marketplaceSearchHint =
      'Buscar plantas, esquejes, herramientas...';

  static const String createListingTitle = 'Nuevo Anuncio';
  static const String createListingPhotosLabel = 'Fotos';
  static const String createListingAddPhotos = 'Añadir fotos';
  static const String createListingPhotosRecommendation =
      'Máximo 5 fotos recomendado';
  static const String createListingTitleLabel = 'Título del anuncio *';
  static const String createListingTitleHint =
      'Ej: Esqueje de Monstera variegata';
  static const String createListingTitleRequired = 'El título es obligatorio';
  static const String createListingTitleMinLength = 'Mínimo 5 caracteres';
  static const String createListingDescriptionLabel = 'Descripción *';
  static const String createListingDescriptionHint =
      'Describe tu producto: estado, tamaño, cuidados especiales...';
  static const String createListingDescriptionRequired =
      'La descripción es obligatoria';
  static const String createListingCategoryLabel = 'Categoría *';
  static const String createListingTypeLabel = 'Tipo de transacción *';
  static const String createListingPriceLabel = 'Precio (€) *';
  static const String createListingPriceHint = 'Ej: 15.00';
  static const String createListingPriceRequired =
      'El precio es obligatorio para ventas';
  static const String createListingPriceInvalid = 'Precio inválido';
  static const String createListingTradeLabel = 'Acepto intercambio por';
  static const String createListingTradeHint =
      'Ej: Cactus San Pedro, Aloe vera...';
  static const String createListingGiveawayNote =
      'Este anuncio aparecerá como "Regalo" y no incluirá precio.';
  static const String createListingLocationLabel = 'Ubicación *';
  static const String createListingLocationNameLabel =
      'Nombre del lugar (opcional)';
  static const String createListingLocationNameHint =
      'Ej: Barrio Salamanca, Madrid';
  static const String createListingSubmitButton = 'Publicar Anuncio';
  static const String createListingPublishingButton = 'Publicando...';
  static const String createListingSuccess = '✅ Anuncio publicado';
  static const String createListingLocationRequired = 'Se requiere ubicación';

  static const String listingDetailAnuncio = 'Anuncio';
  static const String listingDetailNotFound = 'Anuncio no encontrado';
  static const String listingDetailDescriptionLabel = 'Descripcion';
  static const String listingDetailTradeLabel = 'Acepta intercambio por:';
  static const String listingDetailLocationFallback = 'Ubicacion no disponible';
  static const String listingDetailSellerFallback = 'Vendedor';
  static const String listingDetailContactButton = 'Contactar';
  static const String listingDetailContactSoon =
      'Funcion de contacto disponible proximamente';

  // Shared photo picker sheet
  static const String photoPickerGallery = 'Galería';
  static const String photoPickerCamera = 'Cámara';

  // ── Guides ────────────────────────────────────────────────────────────────────
  static const String guidesTitle = 'Guias de Cuidado';
  static const String guidesSearchHint = 'Buscar guias...';

  static const String guideCategoryWatering = 'Riego';
  static const String guideCategoryWateringSubtitle =
      'Consejos sobre frecuencia y tecnicas de riego';
  static const String guideCategoryLight = 'Luz y Sol';
  static const String guideCategoryLightSubtitle =
      'Comprende las necesidades luminicas de tus plantas';
  static const String guideCategoryTemperature = 'Temperatura y Humedad';
  static const String guideCategoryTemperatureSubtitle =
      'Controla el ambiente para un crecimiento optimo';
  static const String guideCategoryPests = 'Plagas y Enfermedades';
  static const String guideCategoryPestsSubtitle =
      'Identifica, previene y trata problemas comunes';

  // ── Location shared strings ───────────────────────────────────────────────────
  static const String locationDenied = 'Permiso de ubicación denegado';
  static const String locationDeniedForever =
      'Permiso de ubicación denegado permanentemente';
  static const String locationPermDenied = 'Permiso denegado permanentemente';
}
