import { useState } from 'react';
import { AppStorage } from '../../../lib/storage.ts';
import { Modal, Upload } from 'antd';
import "../../css/ValidatorSpace/ValidatorSpace.css";
import CarbonUMArket from '../../../abi/CarbonUMArket.json';

const { PlusOutlined } = require('@ant-design/icons');


const getBase64 = (file) =>
    new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.readAsDataURL(file);
        reader.onload = () => resolve(reader.result);
        reader.onerror = (error) => reject(error);
    });

function ValidatorSpace() {
    const appStorage = new AppStorage();
    const [isLoading, setIsLoading] = useState(false);

    const [previewOpen, setPreviewOpen] = useState(false);
    const [previewImage, setPreviewImage] = useState('');
    const [previewTitle, setPreviewTitle] = useState('');
    const [fileList, setFileList] = useState([
        {
            uid: '-1',
            name: 'image.png',
            status: 'done',
            url: 'https://zos.alipayobjects.com/rmsportal/jkjgkEfvpUPVyRjUImniVslZfWPnJuuZ.png',
        },
        {
            uid: '-xxx',
            percent: 50,
            name: 'image.png',
            status: 'uploading',
            url: 'https://zos.alipayobjects.com/rmsportal/jkjgkEfvpUPVyRjUImniVslZfWPnJuuZ.png',
        },
        {
            uid: '-5',
            name: 'image.png',
            status: 'error',
        },
    ]);


	// const onUploadSuccess = (hash) => {
	// 	setIsLoading(false);
	// 	setFile(null);
	// 	message.success(`File uploaded successfully.`);
	// 	closeModal();
	// }

	// const onUploadError = (e) => {
	// 	setIsLoading(false);
	// 	message.error(`An error has ocurred: ${e}`);
	// }


    const uploadFile = async (file) => {
        setIsLoading(true);
        const result = await appStorage.uploadFile(file);
        setIsLoading(false);
        return result;
    }

    const handleCancel = () => setPreviewOpen(false);
    const handlePreview = async (file) => {
      if (!file.url && !file.preview) {
        file.preview = await getBase64(file.originFileObj);
      }
      setPreviewImage(file.url || file.preview);
      setPreviewOpen(true);
      setPreviewTitle(file.name || file.url.substring(file.url.lastIndexOf('/') + 1));
    };
    const handleChange = async ({ fileList: newFileList }) => {
        let lastFile = newFileList[newFileList.length - 1];
        const result = await appStorage.upload({
            buffer: lastFile.originFileObj,
            type: "image/png",
            name: "test",
        });
        lastFile = {
            uid: '-xxx',
            name: 'image.png',
            status: 'done',
            url: result.url
        }
        newFileList[newFileList.length - 1] = lastFile;
        console.log(newFileList);
        setFileList(newFileList);
    };
    const uploadButton = (
      <div>
        <PlusOutlined />
        <div
          style={{
            marginTop: 8,
          }}
        >
          Upload
        </div>
      </div>
    );
    return (
      <div className='validator-space'>
        <Upload
          action="https://run.mocky.io/v3/435e224c-44fb-4773-9faf-380c5e6a2188"
          listType="picture-circle"
          fileList={fileList}
          onPreview={handlePreview}
          onChange={handleChange}
        >
          {fileList.length >= 8 ? null : uploadButton}
        </Upload>
        <Modal open={previewOpen} title={previewTitle} footer={null} onCancel={handleCancel}>
          <img
            alt="example"
            style={{
              width: '100%',
            }}
            src={previewImage}
          />
        </Modal>
      </div>
    );
  



    // return (
    //     <div className="ValidatorSpace">
    //         <h2>Validator Space</h2>
    //         <button onClick={() => {} }>Add evidence</button>
    //     </div>
    // );
}

export default ValidatorSpace;