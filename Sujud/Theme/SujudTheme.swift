import SwiftUI

/// Shared aesthetic color palette and styling constants for Sujud.
/// Inspired by sacred Islamic geometry and calm, respectful minimalism.
public enum SujudTheme {
    /// Deep Islamic Emerald Green - Primary brand color
    public static let primaryGreen = Color(red: 11/255, green: 110/255, blue: 91/255)
    
    /// Deep Forest Dark Background
    public static let deepForest = Color(red: 16/255, green: 35/255, blue: 31/255)
    
    /// Off-white calm background for light mode
    public static let softBackground = Color(red: 244/255, green: 247/255, blue: 245/255)
    
    /// Warm gold / amber accent for highlights and active countdowns
    public static let warmGold = Color(red: 196/255, green: 130/255, blue: 8/255)
    
    /// Vibrant Kaaba alignment green
    public static let alignmentGreen = Color(red: 0/255, green: 168/255, blue: 107/255)
    
    /// Neutral card background adaptable to dark/light mode
    public static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: 0.12) : Color.white
    }
    
    /// Secondary card background
    public static func secondaryCardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: 0.17) : Color(red: 236/255, green: 242/255, blue: 239/255)
    }
}
