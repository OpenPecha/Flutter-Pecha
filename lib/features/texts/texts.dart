/// Texts feature barrel export
///
/// Usage:
/// ```dart
/// import 'package:flutter_pecha/features/texts/texts.dart';
/// ```
library;

// Domain - Entities
export 'domain/entities/text.dart';
export 'domain/entities/section.dart';
export 'domain/entities/segment.dart';
export 'domain/entities/version.dart';

// Domain - Repositories
export 'domain/repositories/texts_repository.dart';

// Domain - Use Cases
export 'domain/usecases/texts_usecases.dart';

// Data - Models
export 'data/models/segment.dart';
export 'data/models/section.dart';
export 'data/models/version.dart';
export 'data/models/translation.dart';
export 'data/models/detail_segment.dart';
export 'data/models/text_detail.dart';
export 'data/models/search/segment_match.dart';
export 'data/models/search/search_response.dart';
export 'data/models/commentary/segment_commentary.dart';
export 'data/models/collections/collections.dart';

// Data - Datasources
export 'data/datasource/text_remote_datasource.dart';
export 'data/datasource/segment_remote_datasource.dart';
export 'data/datasource/collections_remote_datasource.dart';

// Presentation - Providers
export 'presentation/providers/texts_provider.dart';
export 'presentation/providers/segment_provider.dart';
export 'presentation/providers/collections_providers.dart';
export 'presentation/providers/font_size_notifier.dart';
export 'presentation/providers/library_search_state_provider.dart';
export 'presentation/providers/paginated_texts_provider.dart';
export 'presentation/providers/selected_segment_provider.dart';
export 'presentation/providers/text_reading_params_provider.dart';
export 'presentation/providers/text_version_language_provider.dart';
export 'presentation/providers/version_provider.dart';

// Data - Repositories
export 'data/repositories/texts_repository.dart' hide TextsRepository;
export 'data/repositories/segment_repository.dart';
export 'data/repositories/collections_repository.dart';

// Presentation - Screens
export 'presentation/screens/chapters/chapters_screen.dart';
export 'presentation/version_selection/version_selection_screen.dart';

// Presentation - Widgets
export 'presentation/widgets/table_of_contens.dart';
export 'presentation/widgets/language_selector_badge.dart';
export 'presentation/widgets/action_button.dart';
export 'presentation/widgets/font_size_selector.dart';
export 'presentation/widgets/collections_section.dart';
export 'presentation/widgets/commentary_list_item.dart';
export 'presentation/widgets/library_search_delegate.dart';
export 'presentation/widgets/loading_state_widget.dart';
export 'presentation/widgets/section_header.dart';
export 'presentation/widgets/chapter_header.dart';
export 'presentation/widgets/search_text_field.dart';
export 'presentation/widgets/text_list_item.dart';
export 'presentation/widgets/search_result_card.dart';
export 'presentation/widgets/continue_reading_button.dart';
export 'presentation/widgets/text_search_delegate.dart';
export 'presentation/widgets/version_list_item.dart';
export 'presentation/widgets/contents_chapter.dart';
export 'presentation/widgets/text_screen_app_bar.dart';
export 'presentation/widgets/segment_action_bar.dart';
export 'presentation/widgets/commentary_panel.dart';

// Constants
export 'constants/chapter_constants.dart';
export 'constants/text_routes.dart';
export 'constants/text_screen_constants.dart';

// Utils
// export 'utils/language_helper.dart';
export 'utils/helper_functions.dart';
export 'utils/text_highlight_helper.dart';
