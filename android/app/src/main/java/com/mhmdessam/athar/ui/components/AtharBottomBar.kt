package com.mhmdessam.athar.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp

enum class AtharRootTab {
    Timeline,
    Archive
}

@Composable
fun AtharBottomBar(
    selected: AtharRootTab,
    onTimeline: () -> Unit,
    onScan: () -> Unit,
    onArchive: () -> Unit,
    modifier: Modifier = Modifier
) {
    val surface = MaterialTheme.colorScheme.surface
    val border = MaterialTheme.colorScheme.outline

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(98.dp)
    ) {
        Canvas(Modifier.matchParentSize()) {
            val topY = 26.dp.toPx()
            val peakY = 5.dp.toPx()
            val shoulder = 58.dp.toPx()
            val center = size.width / 2f

            val fillPath = Path().apply {
                moveTo(0f, topY)
                lineTo(center - shoulder, topY)
                cubicTo(
                    center - 40.dp.toPx(),
                    topY,
                    center - 34.dp.toPx(),
                    peakY,
                    center,
                    peakY
                )
                cubicTo(
                    center + 34.dp.toPx(),
                    peakY,
                    center + 40.dp.toPx(),
                    topY,
                    center + shoulder,
                    topY
                )
                lineTo(size.width, topY)
                lineTo(size.width, size.height)
                lineTo(0f, size.height)
                close()
            }
            drawPath(fillPath, surface)

            val topEdge = Path().apply {
                moveTo(0f, topY)
                lineTo(center - shoulder, topY)
                cubicTo(
                    center - 40.dp.toPx(),
                    topY,
                    center - 34.dp.toPx(),
                    peakY,
                    center,
                    peakY
                )
                cubicTo(
                    center + 34.dp.toPx(),
                    peakY,
                    center + 40.dp.toPx(),
                    topY,
                    center + shoulder,
                    topY
                )
                lineTo(size.width, topY)
            }
            drawPath(
                path = topEdge,
                color = border,
                style = Stroke(width = 1.dp.toPx())
            )
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.BottomCenter)
                .height(68.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            AtharTabItem(
                glyph = "▤",
                title = "Timeline",
                selected = selected == AtharRootTab.Timeline,
                onClick = onTimeline,
                modifier = Modifier.weight(1f)
            )

            Spacer(Modifier.weight(1f))

            AtharTabItem(
                glyph = "▣",
                title = "Archive",
                selected = selected == AtharRootTab.Archive,
                onClick = onArchive,
                modifier = Modifier.weight(1f)
            )
        }

        Column(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .offset(y = (-1).dp)
                .clickable(onClick = onScan),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(72.dp)
                    .background(surface, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .size(64.dp)
                        .background(MaterialTheme.colorScheme.primary, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "⌗",
                        style = MaterialTheme.typography.headlineSmall,
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                }
            }

            Text(
                text = "Scan",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

@Composable
private fun AtharTabItem(
    glyph: String,
    title: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val color = if (selected) {
        MaterialTheme.colorScheme.primary
    } else {
        MaterialTheme.colorScheme.onSurface
    }

    Column(
        modifier = modifier
            .height(62.dp)
            .clickable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = glyph,
            style = MaterialTheme.typography.titleMedium,
            color = color
        )
        Spacer(Modifier.height(4.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.bodySmall,
            color = color
        )
    }
}
