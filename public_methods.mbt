///|
/// Explicit trait-method exports preserve the API on the October 2026 compiler.
pub extend Severity with Eq::{equal, not_equal}

///|
pub extend Severity with @debug.Debug::{to_repr}

///|
pub extend Position with Eq::{equal, not_equal}

///|
pub extend Position with @debug.Debug::{to_repr}

///|
pub extend Span with Eq::{equal, not_equal}

///|
pub extend Span with @debug.Debug::{to_repr}

///|
pub extend Diagnostic with Eq::{equal, not_equal}

///|
pub extend Diagnostic with @debug.Debug::{to_repr}

///|
pub extend Comment with Eq::{equal, not_equal}

///|
pub extend Comment with @debug.Debug::{to_repr}

///|
pub extend Translation with Eq::{equal, not_equal}

///|
pub extend Translation with @debug.Debug::{to_repr}

///|
pub extend Entry with Eq::{equal, not_equal}

///|
pub extend Entry with @debug.Debug::{to_repr}

///|
pub extend Catalog with @debug.Debug::{to_repr}

///|
pub extend Options with Eq::{equal, not_equal}

///|
pub extend Options with @debug.Debug::{to_repr}

///|
pub extend Statistics with Eq::{equal, not_equal}

///|
pub extend Statistics with @debug.Debug::{to_repr}

///|
pub extend Report with @debug.Debug::{to_repr}

///|
pub extend FormatArgument with Eq::{equal, not_equal}

///|
pub extend FormatArgument with @debug.Debug::{to_repr}

///|
pub extend FormatContract with Eq::{equal, not_equal}

///|
pub extend FormatContract with @debug.Debug::{to_repr}

///|
pub extend FormatDifference with Eq::{equal, not_equal}

///|
pub extend FormatDifference with @debug.Debug::{to_repr}

///|
pub extend PluralExpr with Eq::{equal, not_equal}

///|
pub extend PluralExpr with @debug.Debug::{to_repr}

///|
pub extend PluralRule with Eq::{equal, not_equal}

///|
pub extend PluralRule with @debug.Debug::{to_repr}

///|
pub extend PluralCoverage with Eq::{equal, not_equal}

///|
pub extend PluralCoverage with @debug.Debug::{to_repr}

///|
pub extend HeaderField with Eq::{equal, not_equal}

///|
pub extend HeaderField with @debug.Debug::{to_repr}

///|
pub extend CatalogHeader with @debug.Debug::{to_repr}

///|
pub extend Policy with @debug.Debug::{to_repr}

///|
pub extend RuleDefinition with Eq::{equal, not_equal}

///|
pub extend RuleDefinition with @debug.Debug::{to_repr}

///|
pub extend ContextSummary with Eq::{equal, not_equal}

///|
pub extend ContextSummary with @debug.Debug::{to_repr}

///|
pub extend Reference with Eq::{equal, not_equal}

///|
pub extend Reference with @debug.Debug::{to_repr}

///|
pub extend TemplateDelta with @debug.Debug::{to_repr}

///|
pub extend MarkupOptions with @debug.Debug::{to_repr}

///|
pub extend MarkupError with Eq::{equal, not_equal}

///|
pub extend MarkupError with @debug.Debug::{to_repr}

///|
pub extend MarkupContract with Eq::{equal, not_equal}

///|
pub extend MarkupContract with @debug.Debug::{to_repr}

///|
pub extend ConsistencyOptions with @debug.Debug::{to_repr}

///|
pub extend ProjectFinding with @debug.Debug::{to_repr}

///|
pub extend ProjectPolicy with @debug.Debug::{to_repr}

///|
pub extend ProjectReport with @debug.Debug::{to_repr}
