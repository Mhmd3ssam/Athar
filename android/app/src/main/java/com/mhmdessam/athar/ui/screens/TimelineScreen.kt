package com.mhmdessam.athar.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.mhmdessam.athar.ui.components.AtharLogo
import com.mhmdessam.athar.ui.design.AtharLayout
import com.mhmdessam.athar.ui.design.AtharRadius
import com.mhmdessam.athar.ui.design.AtharSpacing

@Composable
fun TimelineScreen(
    onSettings: () -> Unit,
    onScan: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(top = AtharSpacing.X5)
            .padding(bottom = 96.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = AtharLayout.ScreenInset),
            verticalAlignment = Alignment.Top
        ) {
            Column(
                verticalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                Text(
                    text = "Timeline",
                    style = MaterialTheme.typography.headlineLarge,
                    color = MaterialTheme.colorScheme.onBackground
                )
                Text(
                    text = "Last 7 days",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.62f)
                )
            }

            Spacer(Modifier.weight(1f))

            TextButton(onClick = onSettings) {
                Text(
                    text = "⚙",
                    style = MaterialTheme.typography.headlineSmall,
                    color = MaterialTheme.colorScheme.onBackground
                )
            }
        }

        HorizontalDivider(
            modifier = Modifier
                .padding(horizontal = AtharLayout.ScreenInset)
                .padding(top = AtharSpacing.X4),
            thickness = 1.dp,
            color = MaterialTheme.colorScheme.outline
        )

        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .padding(horizontal = AtharLayout.ScreenInset),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            AtharLogo(
                modifier = Modifier.size(92.dp)
            )

            Spacer(Modifier.height(AtharSpacing.X5))

            Text(
                text = "Track your first paper",
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.onBackground,
                textAlign = TextAlign.Center
            )

            Spacer(Modifier.height(AtharSpacing.X2))

            Text(
                text = "Scan a document and choose its status.\nImages stay on this device.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.62f),
                textAlign = TextAlign.Center
            )

            Spacer(Modifier.height(AtharSpacing.X6))

            Button(
                onClick = onScan,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(AtharRadius.Button)
            ) {
                Text(
                    text = "Scan document",
                    style = MaterialTheme.typography.labelLarge
                )
            }

            Spacer(Modifier.height(AtharSpacing.X4))

            TextButton(onClick = onSettings) {
                Text(
                    text = "Manage statuses",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}
