package com.mhmdessam.athar.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val DarkColorScheme = darkColorScheme(
    primary = AtharColors.PrimaryDark,
    onPrimary = AtharColors.OnPrimaryDark,
    background = AtharColors.BackgroundDark,
    onBackground = AtharColors.TextDark,
    surface = AtharColors.SurfaceDark,
    onSurface = AtharColors.TextDark,
    outline = AtharColors.BorderDark
)

private val LightColorScheme = lightColorScheme(
    primary = AtharColors.PrimaryLight,
    onPrimary = AtharColors.OnPrimaryLight,
    background = AtharColors.BackgroundLight,
    onBackground = AtharColors.TextLight,
    surface = AtharColors.SurfaceLight,
    onSurface = AtharColors.TextLight,
    outline = AtharColors.BorderLight
)

@Composable
fun AtharTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme,
        typography = Typography,
        content = content
    )
}
