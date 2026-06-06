import SwiftUI
import Charts

// MARK: - Design System

enum AppTheme {
    static let wine          = Color(red: 0.65, green: 0.05, blue: 0.15)
    static let appBackground = Color(red: 0.96, green: 0.96, blue: 0.98)
    static let cardBackground = Color.white
    static let softOrange    = Color(red: 0.95, green: 0.50, blue: 0.10)
    static let softGreen     = Color(red: 0.13, green: 0.65, blue: 0.36)
    static let mutedText     = Color.gray
    static let cardCornerRadius: CGFloat = 20
}

extension View {
    func modernCard() -> some View {
        self
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cardCornerRadius)
            .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Risk Level

enum RiskLevel: Equatable {
    case critical   // 80–100 %
    case medium     // 50–79 %
    case low        //  0–49 %

    init(percentage: Double) {
        switch percentage {
        case 80...:   self = .critical
        case 50..<80: self = .medium
        default:      self = .low
        }
    }

    var color: Color {
        switch self {
        case .critical: return AppTheme.wine
        case .medium:   return AppTheme.softOrange
        case .low:      return AppTheme.softGreen
        }
    }

    var label: String {
        switch self {
        case .critical: return "Crítico"
        case .medium:   return "Medio"
        case .low:      return "Bajo"
        }
    }
}

// MARK: - Model

struct StoreClient: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let territoryD: String              // territory_d
    let comercialSubchannelD: String    // comercial_subchannel_d
    let coolers: Int
    let daysWithoutPurchase: Int
    let uniBoxesSoldM: Int              // uni_boxes_sold_m
    let riskPercentage: Double
    let insight: String

    var riskLevel: RiskLevel { RiskLevel(percentage: riskPercentage) }
    var riskColor: Color     { riskLevel.color }
    var isCritical: Bool     { riskLevel == .critical }
    var churnProgressText: String { "\(daysWithoutPurchase)/30 días" }
}

// MARK: - Mock Data

let mockClients: [StoreClient] = [
    StoreClient(name: "Abarrotes Doña Mary",     territoryD: "Aguascalientes",    comercialSubchannelD: "Abarrotes y bodegas", coolers: 2, daysWithoutPurchase: 28, uniBoxesSoldM: 14,  riskPercentage: 92, insight: "La caída de compras coincide con menor frecuencia de visita en Aguascalientes y bajo movimiento en productos fríos. Recomendación: visitar hoy, revisar inventario de Coca-Cola 600 ml y ofrecer promoción de reactivación."),
    StoreClient(name: "Miscelánea El Güero",     territoryD: "Monterrey Norte",   comercialSubchannelD: "Misceláneas",         coolers: 3, daysWithoutPurchase: 25, uniBoxesSoldM: 22,  riskPercentage: 78, insight: "El cliente mantiene 3 coolers asignados, pero lleva 25 días sin compra. Recomendación: confirmar si hay falta de producto, validar exhibición fría y levantar pedido sugerido antes de llegar al día 30."),
    StoreClient(name: "Tiendita San Judas",      territoryD: "CDMX Oriente",      comercialSubchannelD: "Abarrotes y bodegas", coolers: 1, daysWithoutPurchase: 29, uniBoxesSoldM: 6,   riskPercentage: 96, insight: "El riesgo es crítico porque está a 1 día de cumplir churn. La baja puede estar relacionada con poca capacidad de enfriamiento. Recomendación: visita prioritaria y oferta de paquete mixto de alta rotación."),
    StoreClient(name: "Abarrotes La Esquina",    territoryD: "Guadalajara Centro", comercialSubchannelD: "Abarrotes y bodegas", coolers: 2, daysWithoutPurchase: 22, uniBoxesSoldM: 38,  riskPercentage: 45, insight: "El cliente aún no está en zona crítica, pero presenta señales tempranas de abandono. Recomendación: programar visita esta semana y revisar frecuencia de compra del último mes."),
    StoreClient(name: "Mini Súper Lupita",       territoryD: "Puebla Poniente",   comercialSubchannelD: "Super y minisuper",   coolers: 4, daysWithoutPurchase: 27, uniBoxesSoldM: 51,  riskPercentage: 88, insight: "El cliente tiene alta capacidad instalada con 4 coolers, pero lleva 27 días sin comprar. Recomendación: validar abasto, competencia cercana y proponer descuento por volumen."),
    StoreClient(name: "Depósito Los Compadres",  territoryD: "León",              comercialSubchannelD: "Depósitos",           coolers: 5, daysWithoutPurchase: 10, uniBoxesSoldM: 120, riskPercentage: 28, insight: "Cliente estable con alta rotación de producto. Recomendación: mantener frecuencia de visita y reforzar exhibición en temporada de calor.")
]

// MARK: - Enums

enum RiskFilter: String, CaseIterable { case highest = "Mayor Riesgo"; case lowest = "Menor Riesgo" }
enum AppTab { case store, dashboards, home, reports, profile }

// MARK: - Root

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    var body: some View {
        TabView(selection: $selectedTab) {
            PlaceholderView(title: "Tiendas",    subtitle: "Universo de tienditas del Canal Tradicional.",                     icon: "storefront.fill")         .tabItem { Image(systemName: "storefront.fill");     Text("Tienda") }.tag(AppTab.store)
            PlaceholderView(title: "Dashboards", subtitle: "Resumen ejecutivo de riesgo, territorios y tendencia de churn.",  icon: "square.grid.2x2.fill")    .tabItem { Image(systemName: "square.grid.2x2.fill"); Text("Dash") }.tag(AppTab.dashboards)
            DashboardView(clients: mockClients)                                                                                                                  .tabItem { Image(systemName: "house.fill");          Text("Inicio") }.tag(AppTab.home)
            PlaceholderView(title: "Reportes",   subtitle: "Clientes recuperados, en riesgo y perdidos.",                    icon: "folder.fill")                .tabItem { Image(systemName: "folder.fill");         Text("Reportes") }.tag(AppTab.reports)
            PlaceholderView(title: "Perfil",     subtitle: "Información del preventista y desempeño semanal.",               icon: "person.crop.circle.fill")    .tabItem { Image(systemName: "person.crop.circle.fill"); Text("Perfil") }.tag(AppTab.profile)
        }
        .tint(AppTheme.wine)
    }
}

// MARK: - Dashboard

struct DashboardView: View {
    let clients: [StoreClient]
    @State private var riskFilter: RiskFilter = .highest

    private var sortedClients: [StoreClient] {
        riskFilter == .highest
            ? clients.sorted { $0.riskPercentage > $1.riskPercentage }
            : clients.sorted { $0.riskPercentage < $1.riskPercentage }
    }

    // Build pairs for the 2-column grid
    private var clientPairs: [[StoreClient]] {
        stride(from: 0, to: sortedClients.count, by: 2).map {
            Array(sortedClients[$0..<min($0 + 2, sortedClients.count)])
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.appBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {

                        HeaderView()
                        RiskSummaryCard(clients: clients)
                        // Section header
                        Text("Tienditas en Riesgo")
                            .font(.title3).fontWeight(.bold).foregroundStyle(.primary)

                        // Segmented picker
                        Picker("Filtro", selection: $riskFilter) {
                            ForEach(RiskFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)

                        // 2-column grid built with pairs of HStacks
                        // Using explicit HStack pairs avoids GeometryReader issues
                        VStack(spacing: 14) {
                            ForEach(clientPairs, id: \.first?.id) { pair in
                                HStack(spacing: 14) {
                                    ForEach(pair) { client in
                                        NavigationLink {
                                            ClientDetailView(client: client)
                                        } label: {
                                            StoreRiskCard(client: client)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    // Fill empty slot if odd number
                                    if pair.count == 1 {
                                        Color.clear
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: riskFilter)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Header

struct HeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hola, Preventista").font(.title2).fontWeight(.bold)
                Text("Ruta priorizada para hoy").font(.subheadline).foregroundStyle(AppTheme.mutedText)
            }
            Spacer()
            ZStack {
                Circle().fill(AppTheme.wine.opacity(0.12)).frame(width: 46, height: 46)
                Image(systemName: "bell.badge.fill").foregroundStyle(AppTheme.wine)
            }
        }
    }
}

// MARK: - Risk Summary Card (donut chart)

struct RiskSummaryCard: View {
    let clients: [StoreClient]

    private struct Slice: Identifiable {
        let id = UUID(); let label: String; let value: Double; let color: Color
    }
    private var slices: [Slice] {
        let r = clients.filter { $0.riskPercentage >= 50 }.count
        let s = clients.count - r
        return [Slice(label: "En riesgo", value: Double(r), color: AppTheme.wine),
                Slice(label: "Seguros",   value: Double(s), color: AppTheme.softGreen)]
    }
    private var atRisk: Int { clients.filter { $0.riskPercentage >= 50 }.count }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ingresos en riesgo").font(.subheadline).foregroundStyle(AppTheme.mutedText)
                Text("$12 MM MXN").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.wine)
                Text("en riesgo esta semana").font(.callout).foregroundStyle(.primary)
                ForEach(slices) { s in
                    HStack(spacing: 6) {
                        Circle().fill(s.color).frame(width: 8, height: 8)
                        Text(s.label).font(.caption).foregroundStyle(AppTheme.mutedText)
                        Spacer()
                        Text("\(Int(s.value))").font(.caption).fontWeight(.bold).foregroundStyle(s.color)
                    }
                }
            }
            Spacer()
            Chart(slices) { s in
                SectorMark(angle: .value("v", s.value), innerRadius: .ratio(0.54), angularInset: 2)
                    .foregroundStyle(s.color).cornerRadius(4)
            }
            .chartLegend(.hidden)
            .chartBackground { _ in
                VStack(spacing: 0) {
                    Text("\(atRisk)").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.wine)
                    Text("de \(clients.count)").font(.caption2).foregroundStyle(AppTheme.mutedText)
                }
            }
            .frame(width: 100, height: 100)
        }
        .padding(20)
        .modernCard()
    }
}

// MARK: - Audio Briefing

struct AudioBriefingCard: View {
    @State private var isPlaying = false
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(AppTheme.wine.opacity(0.12)).frame(width: 50, height: 50)
                    Image(systemName: "headphones").font(.title2).foregroundStyle(AppTheme.wine)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Briefing de Ruta").font(.headline)
                    Text("ElevenLabs").font(.caption).foregroundStyle(AppTheme.mutedText)
                }
                Spacer()
                Button { isPlaying.toggle() } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.headline).foregroundStyle(.white)
                        .frame(width: 42, height: 42).background(AppTheme.wine).clipShape(Circle())
                }
            }
            HStack(spacing: 10) {
                Text("0:18").font(.caption2).foregroundStyle(AppTheme.mutedText)
                ProgressCapsule(value: isPlaying ? 0.58 : 0.28, color: AppTheme.wine, height: 7)
                Text("1:04").font(.caption2).foregroundStyle(AppTheme.mutedText)
            }
        }
        .padding(16).modernCard()
    }
}

// MARK: - Store Risk Card  ★ REDESIGNED
// Layout: white card with fixed width, gauge circle centered at top (NO text inside gauge),
// risk % and name below, micro-stats at bottom.

struct StoreRiskCard: View {
    let client: StoreClient

    var body: some View {
        VStack(spacing: 0) {

            // ── Gauge area ─────────────────────────────
            ZStack(alignment: .topTrailing) {
                // The gauge itself — text rendered OUTSIDE the ZStack below
                LiquidGauge(
                    value: client.riskPercentage / 100,
                    color: client.riskColor,
                    size: 110,
                    showLabel: true
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 18)
                .padding(.bottom, 10)

                // Level badge top-right corner
                Text(client.riskLevel.label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(client.riskColor)
                    .clipShape(Capsule())
                    .padding(8)
            }

            // ── Text area ──────────────────────────────
            VStack(spacing: 5) {

                // Name
                Text(client.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)

                // Subchannel
                Text(client.comercialSubchannelD)
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.mutedText)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Divider()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)

                // Mini stats row
                HStack(spacing: 0) {
                    MiniStat(icon: "calendar",        value: "\(client.daysWithoutPurchase)d", color: client.riskColor)
                    Divider().frame(height: 22)
                    MiniStat(icon: "shippingbox",     value: "\(client.uniBoxesSoldM)cj",     color: client.riskColor)
                    Divider().frame(height: 22)
                    MiniStat(icon: "snowflake",       value: "\(client.coolers)",              color: client.riskColor)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 14)
        }
        // Fixed width via .frame(maxWidth: .infinity) in the HStack pair;
        // height is intrinsic — do NOT set a fixed height so names can wrap.
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cardCornerRadius)
        .shadow(color: client.riskColor.opacity(0.18), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(client.riskColor.opacity(0.20), lineWidth: 1)
        )
    }
}

/// Tiny icon + value column for the micro-stats strip
private struct MiniStat: View {
    let icon: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 10)).foregroundStyle(color)
            Text(value).font(.system(size: 10, weight: .semibold)).foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Liquid Gauge

struct LiquidGauge: View {
    let value: Double       // 0–1
    let color: Color
    let size: CGFloat
    var showLabel: Bool = true   // toggle the % label inside the circle

    @State private var waveOffset: CGFloat = 0
    @State private var appeared  = false

    private var fill: CGFloat { appeared ? CGFloat(max(0, min(value, 1))) : 0 }

    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.08))

            LiquidWaveShape(fillFraction: fill, waveOffset: waveOffset)
                .fill(color.opacity(0.85))
                .clipShape(Circle())

            LiquidWaveShape(fillFraction: fill, waveOffset: waveOffset + .pi * 0.6)
                .fill(color.opacity(0.28))
                .clipShape(Circle())

            if showLabel {
                Text("\(Int(value * 100))%")
                    .font(.system(size: size * 0.26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: color.opacity(0.9), radius: 1, x: 0, y: 0)
                    .shadow(color: color.opacity(0.9), radius: 3, x: 0, y: 0)
                    .shadow(color: color.opacity(0.7), radius: 6, x: 0, y: 0)
            }

            Circle().strokeBorder(color.opacity(0.30), lineWidth: 2)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0))          { appeared   = true }
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) { waveOffset = .pi * 2 }
        }
    }
}

struct LiquidWaveShape: Shape {
    var fillFraction: CGFloat
    var waveOffset:   CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(fillFraction, waveOffset) }
        set { fillFraction = newValue.first; waveOffset = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let waveH    = rect.height * 0.055
        let waterY   = rect.height * (1 - fillFraction)
        let steps    = Int(rect.width)

        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: waterY))

        for i in 0...steps {
            let x = CGFloat(i)
            let angle = (x / rect.width) * .pi * 2 + waveOffset
            path.addLine(to: CGPoint(x: x, y: waterY + sin(angle) * waveH))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Client Detail View

struct ClientDetailView: View {
    let client: StoreClient
    var body: some View {
        ZStack {
            AppTheme.appBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    ClientHeaderCard(client: client)
                    HStack(spacing: 12) {
                        MetricCard(title: "Coolers",    value: "\(client.coolers)",           icon: "snowflake")
                        MetricCard(title: "Territorio", value: client.territoryD,              icon: "map.fill")
                    }
                    HStack(spacing: 12) {
                        MetricCard(title: "Subcanal",   value: client.comercialSubchannelD,    icon: "tag.fill")
                        MetricCard(title: "Cajas/mes",  value: "\(client.uniBoxesSoldM) cj",  icon: "shippingbox.fill")
                    }
                    MetricCard(title: "Días sin compra", value: "\(client.daysWithoutPurchase) de 30", icon: "calendar.badge.clock", isWide: true)
                    GeminiInsightCard(client: client)
                }
                .padding(20).padding(.bottom, 32)
            }
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ClientHeaderCard: View {
    let client: StoreClient
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                LiquidGauge(value: client.riskPercentage / 100, color: client.riskColor, size: 80, showLabel: true)
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(Int(client.riskPercentage))%")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(client.riskColor)
                    Text(client.riskLevel.label)
                        .font(.caption).fontWeight(.bold).foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(client.riskColor).clipShape(Capsule())
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(client.name).font(.title2).fontWeight(.bold)
                Text("Canal Tradicional · Churn al día 30 sin compra")
                    .font(.subheadline).foregroundStyle(AppTheme.mutedText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20).modernCard()
    }
}

struct MetricCard: View {
    let title: String; let value: String; let icon: String; var isWide: Bool = false
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(AppTheme.wine.opacity(0.10)).frame(width: 40, height: 40)
                Image(systemName: icon).font(.headline).foregroundStyle(AppTheme.wine)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.caption).foregroundStyle(AppTheme.mutedText)
                Text(value).font(.headline).fontWeight(.bold).lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer()
        }
        .padding(14).frame(maxWidth: .infinity).modernCard()
    }
}

struct GeminiInsightCard: View {
    let client: StoreClient
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(AppTheme.wine.opacity(0.12)).frame(width: 44, height: 44)
                    Image(systemName: "sparkles").font(.title3).foregroundStyle(AppTheme.wine)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Insights de Gemini").font(.headline).fontWeight(.bold)
                    Text("Explicación simulada de riesgo").font(.caption).foregroundStyle(AppTheme.mutedText)
                }
            }
            Text(client.insight).font(.subheadline).lineSpacing(4)
            VStack(alignment: .leading, spacing: 10) {
                InsightRow(icon: "exclamationmark.triangle.fill", text: "Prioridad: \(client.isCritical ? "Alta" : "Media")")
                InsightRow(icon: "person.crop.circle.badge.checkmark", text: "Acción: contactar encargado y levantar pedido de recuperación.")
                InsightRow(icon: "cart.fill.badge.plus", text: "Oferta: paquete mixto de alta rotación para venta fría.")
            }
        }
        .padding(20).background(Color.white).cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(AppTheme.wine.opacity(0.20), lineWidth: 1.2))
        .shadow(color: AppTheme.wine.opacity(0.14), radius: 12, x: 0, y: 5)
    }
}

struct InsightRow: View {
    let icon: String; let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).font(.caption).foregroundStyle(AppTheme.wine).frame(width: 18)
            Text(text).font(.caption).fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Shared

struct ProgressCapsule: View {
    let value: Double; let color: Color; let height: CGFloat
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.12))
                Capsule().fill(color).frame(width: max(0, min(value, 1)) * g.size.width)
            }
        }
        .frame(height: height)
    }
}

struct PlaceholderView: View {
    let title: String; let subtitle: String; let icon: String
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.appBackground.ignoresSafeArea()
                VStack(spacing: 18) {
                    ZStack {
                        Circle().fill(AppTheme.wine.opacity(0.12)).frame(width: 80, height: 80)
                        Image(systemName: icon).font(.system(size: 32, weight: .bold)).foregroundStyle(AppTheme.wine)
                    }
                    Text(title).font(.title2).fontWeight(.bold)
                    Text(subtitle).font(.subheadline).foregroundStyle(AppTheme.mutedText)
                        .multilineTextAlignment(.center).padding(.horizontal, 28)
                }
                .padding(24).modernCard().padding(24)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Preview

#Preview { MainTabView() }
