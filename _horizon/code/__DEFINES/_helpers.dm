/// Type is abstract and should be skipped in type iterations, etc.
#define IS_ABSTRACT(datum_type) (initial(datum_type.abstract_type) == datum_type)

/// Returns TRUE if ALL of `flags` are set in `flagvar`.
/// Mirrors legacy modular_septic/code/__DEFINES/zseptic_defines/bitflags.dm.
#define CHECK_MULTIPLE_BITFIELDS(flagvar, flags) (((flagvar) & (flags)) == (flags))
