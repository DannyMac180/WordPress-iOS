import Foundation

class PluginViewController: UITableViewController {
    var plugin: PluginState {
        didSet {
            viewModel.plugin = plugin
        }
    }

    fileprivate lazy var handler: ImmuTableViewHandler = {
        let handler = ImmuTableViewHandler(takeOver: self)
        handler.automaticallyDeselectCells = true
        return handler
    }()

    fileprivate let viewModel: PluginViewModel

    init(plugin: PluginState, capabilities: SitePluginCapabilities, siteID: Int, service: PluginServiceRemote) {
        self.plugin = plugin
        viewModel = PluginViewModel(plugin: plugin, capabilities: capabilities, siteID: siteID, service: service)
        super.init(style: .grouped)
        viewModel.onModelChange = bindViewModel
        viewModel.present = { [weak self] viewController in
            self?.present(viewController, animated: true)
        }
        viewModel.dismiss = { [weak self] in
            guard let navigationController = self?.navigationController,
                navigationController.topViewController == self else {
                    return
            }
            navigationController.popViewController(animated: true)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        ImmuTable.registerRows(PluginViewModel.immutableRows, tableView: tableView)
        bindViewModel()
    }

    func bindViewModel() {
        handler.viewModel = viewModel.tableViewModel
        title = viewModel.title
    }
}
