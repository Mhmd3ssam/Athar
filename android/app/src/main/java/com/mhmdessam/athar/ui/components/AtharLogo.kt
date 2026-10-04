package com.mhmdessam.athar.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import com.mhmdessam.athar.ui.theme.AtharColors

@Composable
fun AtharLogo(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier.background(
            color = AtharColors.LogoGreen,
            shape = RoundedCornerShape(22.dp)
        )
    ) {
        Canvas(Modifier.fillMaxSize()) {
            val w = size.width
            val h = size.height
            val stroke = w * 0.055f

            val document = Path().apply {
                moveTo(w * 0.29f, h * 0.22f)
                lineTo(w * 0.62f, h * 0.22f)
                lineTo(w * 0.76f, h * 0.36f)
                lineTo(w * 0.76f, h * 0.67f)

                moveTo(w * 0.62f, h * 0.22f)
                lineTo(w * 0.62f, h * 0.36f)
                lineTo(w * 0.76f, h * 0.36f)

                moveTo(w * 0.29f, h * 0.22f)
                lineTo(w * 0.29f, h * 0.78f)
                lineTo(w * 0.58f, h * 0.78f)
            }

            drawPath(
                path = document,
                color = AtharColors.LogoIvory,
                style = Stroke(
                    width = stroke,
                    cap = StrokeCap.Round,
                    join = StrokeJoin.Round
                )
            )

            drawLine(
                color = AtharColors.LogoIvory,
                start = Offset(w * 0.39f, h * 0.48f),
                end = Offset(w * 0.54f, h * 0.48f),
                strokeWidth = stroke * 0.8f,
                cap = StrokeCap.Round
            )

            drawLine(
                color = AtharColors.LogoIvory,
                start = Offset(w * 0.39f, h * 0.56f),
                end = Offset(w * 0.50f, h * 0.56f),
                strokeWidth = stroke * 0.8f,
                cap = StrokeCap.Round
            )

            listOf(
                Offset(w * 0.40f, h * 0.66f),
                Offset(w * 0.44f, h * 0.71f),
                Offset(w * 0.50f, h * 0.74f),
                Offset(w * 0.57f, h * 0.74f),
                Offset(w * 0.63f, h * 0.71f)
            ).forEach { point ->
                drawCircle(
                    color = AtharColors.LogoIvory,
                    radius = stroke * 0.32f,
                    center = point
                )
            }

            drawCircle(
                color = AtharColors.LogoGold,
                radius = w * 0.075f,
                center = Offset(w * 0.70f, h * 0.66f)
            )
        }
    }
}
