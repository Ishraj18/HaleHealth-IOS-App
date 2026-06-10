import CoreGraphics

/// Corner-radius scale. `pill` is an arbitrarily large value that fully rounds
/// the shorter axis of a rectangle into a capsule.
public enum HHRadius {
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let pill: CGFloat = 999
}
