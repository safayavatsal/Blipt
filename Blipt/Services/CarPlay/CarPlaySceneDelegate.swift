import CarPlay

/// CarPlay scene delegate — shows recent scans on the car display.
/// Requires CarPlay entitlement and Info.plist configuration.
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        showRecentScans()
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
    }

    private func showRecentScans() {
        let scans = loadRecentScans()

        let items: [CPListItem] = scans.prefix(10).map { scan in
            let item = CPListItem(
                text: scan.plate,
                detailText: [scan.stateName, scan.districtName].compactMap { $0 }.joined(separator: ", ")
            )
            item.handler = { [weak self] _, completion in
                self?.showScanDetail(scan)
                completion()
            }
            return item
        }

        let section = CPListSection(items: items, header: "Recent Scans", sectionIndexTitle: nil)
        let listTemplate = CPListTemplate(title: "Blipt", sections: [section])

        if items.isEmpty {
            listTemplate.emptyViewTitleVariants = ["No Scans Yet"]
            listTemplate.emptyViewSubtitleVariants = ["Scan a plate on your iPhone"]
        }

        interfaceController?.setRootTemplate(listTemplate, animated: true, completion: nil)
    }

    private func showScanDetail(_ scan: RecentScan) {
        let items = [
            CPListItem(text: "Plate", detailText: scan.plate),
            CPListItem(text: "State", detailText: scan.stateName ?? "Unknown"),
            CPListItem(text: "District", detailText: scan.districtName ?? "Unknown"),
        ]

        let section = CPListSection(items: items)
        let detail = CPListTemplate(title: scan.plate, sections: [section])
        interfaceController?.pushTemplate(detail, animated: true, completion: nil)
    }

    // MARK: - Data

    private struct RecentScan: Codable {
        let plate: String
        let stateName: String?
        let districtName: String?
    }

    private func loadRecentScans() -> [RecentScan] {
        guard let defaults = UserDefaults(suiteName: "group.com.blipt.shared"),
              let data = defaults.data(forKey: "widget_recent_scans"),
              let items = try? JSONDecoder().decode([RecentScan].self, from: data) else {
            return []
        }
        return items
    }
}
