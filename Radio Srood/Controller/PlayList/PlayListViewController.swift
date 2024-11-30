//
//  PlayListViewController.swift
//  Radio Srood
//
//  Created by Tech on 22/05/2023.
//  Copyright © 2023 Appteve. All rights reserved.
//

import UIKit

protocol PlayListViewControllerDelegate : AnyObject{
    func songSavedToList()
}

class PlayListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var playList = [PlayListModel]()
    var songToSave = SongModel()
    weak var delegate : PlayListViewControllerDelegate?
    var isFromMyMusic = false
   
    override func viewDidLoad() {
        super.viewDidLoad()
        self.playList = UserDefaultsManager.shared.playListsData
        self.tableView.reloadData()

        // Do any additional setup after loading the view.
    }
    @IBAction func actionCancel(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func actionNewList(_ sender: Any) {
        alertWithTextField(title: "Create Playlist", message: "", placeholder: "Enter Playlist name") { result in
            if result != ""{
                let newPlayList = PlayListModel()
                newPlayList.name = result
                self.playList.append(newPlayList)
                UserDefaultsManager.shared.playListsData = self.playList
                self.tableView.reloadData()
            }
        }
    }
    
    public func alertWithTextField(title: String? = nil, message: String? = nil, placeholder: String? = nil, completion: @escaping ((String) -> Void) = { _ in }) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField() { newTextField in
            newTextField.placeholder = placeholder
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completion("") })
        alert.addAction(UIAlertAction(title: "Create Playlist", style: .default) { action in
            if
                let textFields = alert.textFields,
                let tf = textFields.first,
                let result = tf.text
            { completion(result) }
            else
            { completion("") }
        })
        self.present(alert, animated: true)
    }
}

extension PlayListViewController : UITableViewDelegate , UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayListTableViewCell", for: indexPath) as! PlayListTableViewCell
        cell.configureView(list: self.playList[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isFromMyMusic{
            let playListSongs = self.playList[indexPath.row].songs.map { $0.convertToPodcastModel() }
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "MyMusicViewController") as! MyMusicViewController
            vc.isForLikes = true
            vc.trackData = playListSongs
            self.present(vc, animated: true)
        }
        else{
            let selectedPlaylist = self.playList[indexPath.row]

            if selectedPlaylist.songs.contains(where: { $0.trackid == songToSave.trackid }) {
                // Song with the same track ID already exists in the playlist, show a message or handle accordingly
                self.showToast(message: "Song already added in to the Playlist", font: .systemFont(ofSize: 12.0))
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.dismiss(animated: true)
                }

            } else {
                // Song with a different track ID, add it to the playlist
                selectedPlaylist.songs.append(songToSave)
                UserDefaultsManager.shared.playListsData = self.playList
                delegate?.songSavedToList()
                self.showToast(message: "Successfully added to Playlist", font: .systemFont(ofSize: 12.0))
                
                // Dismiss the view after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.dismiss(animated: true)
                }
            }
        }
    }
}
