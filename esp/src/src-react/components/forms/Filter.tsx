import * as React from "react";
import { DefaultButton, PrimaryButton, Stack } from "@fluentui/react";
import { useOnEvent } from "@fluentui/react-hooks";
import nlsHPCC from "src/nlsHPCC";
import { MessageBox } from "../../layouts/MessageBox";
import { Fields, Values } from "./Fields";
import { TableForm } from "./Forms";

interface FilterProps {
    filterFields: Fields;
    onApply: (values: Values) => void;

    showFilter: boolean;
    setShowFilter: (_: boolean) => void;
}

export const Filter: React.FunctionComponent<FilterProps> = ({
    filterFields,
    onApply,
    showFilter,
    setShowFilter
}) => {

    const [doSubmit, setDoSubmit] = React.useState(false);
    const [doReset, setDoReset] = React.useState(false);

    const closeFilter = React.useCallback(() => setShowFilter(false), [setShowFilter]);

    const handleKeyup = React.useCallback((evt) => {
        if (!showFilter) return;
        if (evt.code === "Enter") {
            setDoSubmit(true);
            closeFilter();
        }
    }, [closeFilter, showFilter]);
    useOnEvent(document, "keyup", handleKeyup, true);

    return <MessageBox title={nlsHPCC.Filter} show={showFilter} setShow={closeFilter}
        footer={<>
            <PrimaryButton text={nlsHPCC.Apply} onClick={() => { setDoSubmit(true); closeFilter(); }} />
            <DefaultButton text={nlsHPCC.Clear} onClick={() => { setDoReset(true); }} />
        </>}>
        <Stack>
            <TableForm
                fields={filterFields}
                doSubmit={doSubmit}
                doReset={doReset}
                onSubmit={fields => {
                    setDoSubmit(false);
                    onApply(fields);
                }}
                onReset={() => {
                    setDoReset(false);
                }}
            />
        </Stack>
    </MessageBox>;
};