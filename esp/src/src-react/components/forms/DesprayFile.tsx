import * as React from "react";
import { Checkbox, ContextualMenu, IconButton, IDragOptions, mergeStyleSets, Modal, PrimaryButton, Stack, TextField, } from "@fluentui/react";
import { useId } from "@fluentui/react-hooks";
import { useForm, Controller } from "react-hook-form";
import nlsHPCC from "src/nlsHPCC";
import { useFile } from "../../hooks/file";
import * as FileSpray from "src/FileSpray";
import { TargetDropzoneTextField, TargetFolderTextField, TargetServerTextField } from "./Fields";
import * as FormStyles from "./landing-zone/styles";
import { pushUrl } from "../../util/history";

interface DesprayFileFormValues {
    destGroup: string;
    destIP: string;
    destPath: string;
    targetName: string;
    splitprefix: string;
    overwrite: boolean;
    SingleConnection: boolean;
    wrap: boolean;
}

const defaultValues: DesprayFileFormValues = {
    destGroup: "",
    destIP: "",
    destPath: "",
    targetName: "",
    splitprefix: "",
    overwrite: false,
    SingleConnection: false,
    wrap: false
};

interface DesprayFileProps {
    cluster: string;
    logicalFile: string;

    showForm: boolean;
    setShowForm: (_: boolean) => void;
}

export const DesprayFile: React.FunctionComponent<DesprayFileProps> = ({
    cluster,
    logicalFile,
    showForm,
    setShowForm
}) => {

    const [file] = useFile(cluster, logicalFile);
    const [machine, setMachine] = React.useState<string>("");
    const [directory, setDirectory] = React.useState<string>("/");
    const [pathSep, setPathSep] = React.useState<string>("/");
    const [os, setOs] = React.useState<number>();

    const { handleSubmit, control, reset } = useForm<DesprayFileFormValues>({ defaultValues });

    const closeForm = React.useCallback(() => {
        setShowForm(false);
    }, [setShowForm]);

    const onSubmit = React.useCallback(() => {
        handleSubmit(
            (data, evt) => {
                const request = {
                    ...data,
                    destPath: [data.destPath, data.targetName].join(pathSep),
                    sourceLogicalName: logicalFile
                };
                FileSpray.Despray({ request: request }).then(response => {
                    closeForm();
                    pushUrl(`/dfuworkunits/${response?.DesprayResponse?.wuid}`);
                });
            },
            err => {
                console.log(err);
            }
        )();
    }, [closeForm, handleSubmit, logicalFile, pathSep]);

    const titleId = useId("title");

    const dragOptions: IDragOptions = {
        moveMenuItemText: nlsHPCC.Move,
        closeMenuItemText: nlsHPCC.Close,
        menu: ContextualMenu,
    };

    const componentStyles = mergeStyleSets(
        FormStyles.componentStyles,
        {
            container: {
                minWidth: 440,
            }
        }
    );

    React.useEffect(() => {
        const newValues = { ...defaultValues, targetName: file?.Filename };
        reset(newValues);
    }, [file?.Filename, reset]);

    return <Modal
        titleAriaId={titleId}
        isOpen={showForm}
        onDismiss={closeForm}
        isBlocking={false}
        containerClassName={componentStyles.container}
        dragOptions={dragOptions}
    >
        <div className={componentStyles.header}>
            <span id={titleId}>{nlsHPCC.Despray}</span>
            <IconButton
                styles={FormStyles.iconButtonStyles}
                iconProps={FormStyles.cancelIcon}
                ariaLabel={nlsHPCC.CloseModal}
                onClick={closeForm}
            />
        </div>
        <div className={componentStyles.body}>
            <Stack>
                <Controller
                    control={control} name="destGroup"
                    render={({
                        field: { onChange, name: fieldName, value },
                        fieldState: { error }
                    }) => <TargetDropzoneTextField
                            key={fieldName}
                            label={nlsHPCC.DropZone}
                            required={true}
                            selectedKey={value}
                            placeholder={nlsHPCC.SelectValue}
                            onChange={(evt, option) => {
                                setDirectory(option["path"] as string);
                                if (option["path"].indexOf("\\") > -1) {
                                    setPathSep("\\");
                                }
                                onChange(option.key);
                            }}
                            errorMessage={error && error.message}
                        />}
                    rules={{
                        required: `${nlsHPCC.SelectA} ${nlsHPCC.DropZone}`
                    }}
                />
                <Controller
                    control={control} name="destIP"
                    render={({
                        field: { onChange, name: fieldName, value },
                        fieldState: { error }
                    }) => <TargetServerTextField
                            key={fieldName}
                            required={true}
                            label={nlsHPCC.IPAddress}
                            selectedKey={value}
                            placeholder={nlsHPCC.SelectValue}
                            onChange={(evt, option) => {
                                setMachine(option.key as string);
                                setOs(option["OS"] as number);
                                onChange(option.key);
                            }}
                            errorMessage={error && error.message}
                        />}
                    rules={{
                        required: nlsHPCC.ValidationErrorRequired
                    }}
                />
                <Controller
                    control={control} name="destPath"
                    render={({
                        field: { onChange, name: fieldName, value },
                        fieldState: { error }
                    }) => <TargetFolderTextField
                            key={fieldName}
                            label={nlsHPCC.Path}
                            pathSepChar={pathSep}
                            machineAddress={machine}
                            machineDirectory={directory}
                            machineOS={os}
                            required={true}
                            placeholder={nlsHPCC.SelectValue}
                            onChange={(evt, option) => {
                                onChange(option.key);
                            }}
                            errorMessage={error && error.message}
                        />}
                    rules={{
                        required: nlsHPCC.ValidationErrorRequired,
                    }}
                />
                <Controller
                    control={control} name="targetName"
                    render={({
                        field: { onChange, name: fieldName, value },
                        fieldState: { error }
                    }) => <TextField
                            name={fieldName}
                            onChange={onChange}
                            required={true}
                            label={nlsHPCC.TargetName}
                            value={value}
                            errorMessage={error && error.message}
                        />}
                    rules={{
                        required: nlsHPCC.ValidationErrorRequired
                    }}
                />
                <Controller
                    control={control} name="splitprefix"
                    render={({
                        field: { onChange, name: fieldName, value }
                    }) => <TextField
                            name={fieldName}
                            onChange={onChange}
                            label={nlsHPCC.SplitPrefix}
                            value={value}
                        />}
                />
            </Stack>
            <Stack>
                <table className={componentStyles.twoColumnTable}>
                    <tbody><tr>
                        <td><Controller
                            control={control} name="overwrite"
                            render={({
                                field: { onChange, name: fieldName, value }
                            }) => <Checkbox name={fieldName} checked={value} onChange={onChange} label={nlsHPCC.Overwrite} />}
                        /></td>
                        <td><Controller
                            control={control} name="SingleConnection"
                            render={({
                                field: { onChange, name: fieldName, value }
                            }) => <Checkbox name={fieldName} checked={value} onChange={onChange} label={nlsHPCC.UseSingleConnection} />}
                        /></td>
                    </tr>
                        <tr>
                            <td><Controller
                                control={control} name="wrap"
                                render={({
                                    field: { onChange, name: fieldName, value }
                                }) => <Checkbox name={fieldName} checked={value} onChange={onChange} label={nlsHPCC.PreserveParts} />}
                            /></td>
                        </tr></tbody>
                </table>
            </Stack>

            <Stack horizontal horizontalAlign="space-between" verticalAlign="end" styles={FormStyles.buttonStackStyles}>
                <PrimaryButton text={nlsHPCC.Despray} onClick={handleSubmit(onSubmit)} />
            </Stack>
        </div>
    </Modal>;
};