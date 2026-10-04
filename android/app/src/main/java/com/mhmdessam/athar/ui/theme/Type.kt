package com.mhmdessam.athar.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

val Typography = Typography(
    headlineLarge = TextStyle(
        fontSize = 32.sp,
        lineHeight = 38.sp,
        fontWeight = FontWeight.Bold
    ),
    headlineSmall = TextStyle(
        fontSize = 22.sp,
        lineHeight = 28.sp,
        fontWeight = FontWeight.SemiBold
    ),
    titleMedium = TextStyle(
        fontSize = 17.sp,
        lineHeight = 22.sp,
        fontWeight = FontWeight.Medium
    ),
    bodyLarge = TextStyle(
        fontSize = 16.sp,
        lineHeight = 23.sp,
        fontWeight = FontWeight.Normal
    ),
    labelLarge = TextStyle(
        fontSize = 16.sp,
        lineHeight = 20.sp,
        fontWeight = FontWeight.SemiBold
    ),
    bodySmall = TextStyle(
        fontSize = 13.sp,
        lineHeight = 18.sp,
        fontWeight = FontWeight.Normal
    )
)
